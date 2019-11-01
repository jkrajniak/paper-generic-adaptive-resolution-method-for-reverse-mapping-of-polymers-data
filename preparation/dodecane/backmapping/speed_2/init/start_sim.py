"""
Simulation of Dodecane
"""

import argparse
import espressopp  # NOQA
import math  # NOQA
try:
    import MPI
except ImportError:
    from mpi4py import MPI
import time

import h5md_analysis as serial_h5md
import tools

kb = 0.0083144621  # GROMACS, kJ/molK

dt = 0.001
max_cutoff = 1.4
lj_cutoff = 1.4
cg_cutoff = 1.5

def _args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--conf', required=True)
    parser.add_argument('--top', required=True)
    parser.add_argument('--node_grid')
    parser.add_argument('--skin', type=float)
    parser.add_argument('--coord')
    parser.add_argument('--resolution', default=0.0, type=float)
    parser.add_argument('--res_rate', type=float, default=0.1)
    parser.add_argument('--eq', type=int, default=10000)
    parser.add_argument('--gamma', type=float, default=0.5)
    parser.add_argument('--int_step', default=1000, type=int)
    parser.add_argument('--long', default=10000, type=int)
    parser.add_argument('--rng_seed', default=12345, type=int)
    parser.add_argument('--output_prefix', default='', type=str)
    parser.add_argument('--thermostat', default='lv', choices=('lv', 'vr'))
    parser.add_argument('--temperature', default=423.0, type=float)
    return parser.parse_args()


def main():  #NOQA
    args = _args()

    time0 = time.time()
    input_conf = espressopp.tools.gromacs.read(args.conf, args.top)
    
    # import IPython; IPython.embed()
    N_atoms = len(input_conf.types)
    density = sum(input_conf.masses) / (input_conf.Lx * input_conf.Ly * input_conf.Lz)
    box = (input_conf.Lx, input_conf.Ly, input_conf.Lz)
    print('Setting up simulation...')
    print('Density = {}'.format(density))
    print('Box = {}'.format(box))

    # Tune simulation parameter according to arguments
    integrator_step = args.int_step
    k_eq_step = int(args.eq/integrator_step)
    long_step = int(args.long/integrator_step)
    dynamic_res_time = int(int(1.0/args.res_rate)/integrator_step) if args.res_rate > 0.0 else 0
    sim_step = dynamic_res_time + k_eq_step + long_step
    end_dynamic_res_time = k_eq_step + dynamic_res_time
    if end_dynamic_res_time == k_eq_step:
        end_dynamic_res_time += 1

    if args.skin:
        skin = args.skin
    else:
        skin = 0.16

    print('Running with box {}'.format(box))
    print('Skin: {}'.format(skin))
    print('RNG Seed: {}'.format(args.rng_seed))

    system = tools.System(kb=kb)
    system.rng = espressopp.esutil.RNG(args.rng_seed)
    system.bc = espressopp.bc.OrthorhombicBC(system.rng, box)
    system.skin = skin
    if args.node_grid:
        nodeGrid = map(int, args.node_grid.split(','))
    else:
        nodeGrid = espressopp.tools.decomp.nodeGrid(MPI.COMM_WORLD.size)
    print('Number of nodes {}, node-grid: {}'.format(
        MPI.COMM_WORLD.size, nodeGrid))
    cellGrid = espressopp.tools.decomp.cellGrid(box, nodeGrid, max_cutoff, skin)
    print('Cell grid: {}'.format(cellGrid))

    system.storage = espressopp.storage.DomainDecompositionAdress(system, nodeGrid, cellGrid)
    integrator = espressopp.integrator.VelocityVerlet(system)
    integrator.dt = dt
    
    part_prop, all_particles, adress_tuple = tools.genParticleList(
        input_conf, use_velocity=True, adress=True)
    particle_ids = [x[0] for x in all_particles]
    print('Reads {} particles with properties {}'.format(len(all_particles), part_prop))

    if args.coord:
        import h5py
        print("Reading coordinates from {}".format(args.coord))
        h5coord = h5py.File(args.coord)
        pos = h5coord['/particles/atoms/position/value'][-1]
        for pid, p in enumerate(pos):
            all_particles[pid][3] = espressopp.Real3D(p)
        h5coord.close()
    
    system.storage.addParticles(all_particles, *part_prop)
    adress_fixed_list = espressopp.FixedTupleListAdress(system.storage)
    adress_fixed_list.addTuples(adress_tuple)
    system.storage.setFixedTuplesAdress(adress_fixed_list)
    
    system.storage.decompose()

# Exclude all bonded interaction from the lennard jones
    exclusionlist = input_conf.exclusions
    print('Excluded pairs from LJ interaction: {}'.format(len(exclusionlist)))
    
    verletlist = espressopp.VerletListAdress(
        system,
        cutoff=max_cutoff,
        adrcut=max_cutoff,
        dEx=0.0,
        dHy=box[0],
        adrCenter=[0.5*box[0], 0.5*box[0], 0.5*box[0]],
        exclusionlist=exclusionlist
        )

    vl_interaction, bondedinteractions, angleinteractions, dihedralinteractions, pairinteractions, cg_vl_interaction = (
        {}, {}, {}, {}, {}, {})
    vl_interaction = tools.setLennardJonesInteractions(
        system, input_conf, verletlist, lj_cutoff, input_conf.nonbond_params,
        ftpl=adress_fixed_list)
    bondedinteractions = tools.setBondedInteractions(
        system, input_conf, ftpl=adress_fixed_list)
    angleinteractions = tools.setAngleInteractions(
        system, input_conf, ftpl=adress_fixed_list)
    dihedralinteractions = tools.setDihedralInteractions(
        system, input_conf, ftpl=adress_fixed_list)
    pairinteractions = tools.setPairInteractions(
        system, input_conf, lj_cutoff, ftpl=adress_fixed_list)

    cg_vl_interaction = tools.setTabulatedInteractions(system, input_conf.atomtypeparams,
        vl=verletlist, cutoff=cg_cutoff, interaction=vl_interaction, ftpl=adress_fixed_list)
    
    #import IPython, sys; IPython.embed(); sys.exit(1)

    print('='*10)
    print('Bonds: {}'.format(sum(len(x) for x in input_conf.bondtypes.values())))
    print('Angles: {}'.format(sum(len(x) for x in input_conf.angletypes.values())))
    print('Dihedrals: {}'.format(sum(len(x) for x in input_conf.dihedraltypes.values())))
    print('Pairs: {}'.format(sum(len(x) for x in input_conf.pairtypes.values())))
    print('='*10)
    
    dynamic_res = espressopp.integrator.DynamicResolution(
        system,
        verletlist,
        adress_fixed_list,
        args.res_rate)
    integrator.addExtension(dynamic_res)
    dynamic_res.active = False

# Define the thermostat
    if args.temperature:
        temperature = args.temperature*kb
    print('Temperature: {}, gamma: {}'.format(temperature, args.gamma))
    print('Thermostat: {}'.format(args.thermostat))
    if args.thermostat == 'lv':
        thermostat = espressopp.integrator.LangevinThermostat(system)
        thermostat.temperature = temperature
        thermostat.adress = True
        thermostat.gamma = args.gamma
    elif args.thermostat == 'vr':
        thermostat = espressopp.integrator.StochasticVelocityRescaling(system)
        thermostat.temperature = temperature
        thermostat.coupling = args.gamma
    integrator.addExtension(thermostat)

    print("Added tuples, decomposing now ...")
    espressopp.tools.AdressDecomp(system, integrator)
# Write the warmup configuration

# --- below is the simulation --- #
# warmup
    print('Trajectory saved to: {}but_{}.h5'.format(args.output_prefix, args.res_rate))
    h5dump = serial_h5md.DumpH5MD(
        '{}but_{}.h5'.format(args.output_prefix, args.res_rate),
        system,
        integrator,
        edges=list(box),
        particle_ids=particle_ids,
        unfolded=True,
        save_vel=False
        )

    h5dump.dump()
    h5dump.analyse()
    h5dump.flush()

    print('Energy saved to: {}energy_{}_.csv'.format(args.output_prefix, args.res_rate))
    system_analysis = espressopp.analysis.SystemAnalysis(
        system,
        integrator,
        '{}energy_{}_.csv'.format(args.output_prefix, args.res_rate))
    system_analysis.add_observable('res', espressopp.analysis.Resolution(system, dynamic_res))
    system_analysis.add_observable('lj', espressopp.analysis.PotentialEnergy(system, vl_interaction))
    for (lb, cross), interHarmonic in bondedinteractions.iteritems():
        system_analysis.add_observable('bond_%d%s' % (lb, '_cross' if cross else ''),
                                       espressopp.analysis.PotentialEnergy(system, interHarmonic), False)
    for (lb, cross), interAngularHarmonic in angleinteractions.iteritems():
        system_analysis.add_observable('angle_%d%s' % (lb, '_cross' if cross else ''),
                                       espressopp.analysis.PotentialEnergy(system, interAngularHarmonic), False)
    for (lb, cross), interDihHarmonic in dihedralinteractions.iteritems():
       system_analysis.add_observable('dihedral_%d%s' % (lb, '_cross' if cross else ''),
                                      espressopp.analysis.PotentialEnergy(system, interDihHarmonic), False)
    for (lb, cross), interaction14 in pairinteractions.iteritems():
        system_analysis.add_observable('lj-14_%d%s' % (lb, '_cross' if cross else ''),
                                       espressopp.analysis.PotentialEnergy(system, interaction14), False)

    ext_analysis = espressopp.integrator.ExtAnalyze(system_analysis, 100)
    integrator.addExtension(ext_analysis)
    
    # dump_gro_adress = espressopp.io.DumpGROAdress(system, adress_fixed_list, integrator, filename='traj.gro', append=True)
    # ext_dump = espressopp.integrator.ExtAnalyze(dump_gro_adress, 100)
    # integrator.addExtension(ext_dump)

    system_analysis.dump()
    
    # total_velocity = espressopp.analysis.TotalVelocity(system)
    # total_velocity.reset()
    # ext_remove_com = espressopp.integrator.ExtAnalyze(total_velocity, 1000)
    # integrator.addExtension(ext_remove_com)

    print('Simulation for steps: %d' % (sim_step*integrator_step))
    print('Dynamic resolution, rate={}'.format(args.res_rate))
    print('CG equilibration for {}'.format(k_eq_step*integrator_step))
    print('Measuring energy with higher resolution for {}'.format(
        (end_dynamic_res_time-k_eq_step)*integrator_step))
    print('Long run for {}'.format(long_step*integrator_step))
    
    for k in range(sim_step):
        if k == k_eq_step:
            print('End of CG simulation. Start dynamic resolution')
            dynamic_res.active = True
            ext_analysis.interval = 1
            # ext_dump.interval = 50
        if k == end_dynamic_res_time:
            print('End of dynamic resolution, change energy measuring accuracy to 500')
            ext_analysis.interval = 500
            # ext_dump.interval = 100
        integrator.run(integrator_step)
        # total_velocity.reset()
        h5dump.dump()
        if k % 10 == 0:
            h5dump.flush()
        system_analysis.info()
    h5dump.dump()
    h5dump.close()

    print('finished!')
    espressopp.tools.analyse.final_info(system, integrator, verletlist, time0, time.time())


if __name__ == '__main__':
    main()
