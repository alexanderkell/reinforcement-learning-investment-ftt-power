function result = run_matlab(a, b)

    
    import ray.rllib.env.policy_client.*
    import ray.rllib.env.*
    import gym.*
    import numpy.*
    
    import reinforcement_learning_client_server.*

    address = strcat('http://127.0.0.1:', num2str(9914));
    client = py.ray.rllib.env.PolicyClient(address);

    eid = client.start_episode();

