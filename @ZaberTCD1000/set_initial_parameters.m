function set_initial_parameters(z)

% Initialize Zaber parameters:
    set_microsteps_per_step(z,1) % persists in nonvolatile memory, don't need everytime.
    set_target_speed(z,100)
    set_acceleration(z,100)

    renumber_all(z)

end