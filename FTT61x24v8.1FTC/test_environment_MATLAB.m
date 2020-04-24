
import ray.rllib.env.policy_client.*
import gym.*
import reinforcement_learning_client_server.*
import numpy.*
import gym.Env.*

py.importlib.import_module('reinforcement_learning_client_server')



disp(py.reinforcement_learning_client_server.FTTPowerEnvironment(1, 2))

client = py.ray.rllib.env.policy_client.PolicyClient('http://127.0.0.1:9900')

eid = client.start_episode()

obs = env.reset()
rewards = 0
while true
    action = client.get_action(eid, obs);

    list = env.step(action)
    obs = list{1};
    reward = list{2};
    done = list{3};
    info = list{4};
    rewards = rewards + reward;
    client.log_returns(eid, reward, info)
    if done
        if rewards >= 1000
            disp("Target reward achieved, exiting")
            break
        rewards = 0;
        client.end_episode(eid, obs)
        obs = env.reset()
        eid = client.start_episode()
        end
    end
end

