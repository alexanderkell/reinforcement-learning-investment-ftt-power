
% pyenv('Version','/Users/alexanderkell/.pyenv/shims/python3')


import ray.rllib.env.policy_client.*
import gym.*
import reinforcement_learning_client_server.*
import numpy.*
import gym.Env.*

% import reinforcement_learning_client_server.*
% rl_client_server = py.importlib.import_module('reinforcement_learning_client_server');
py.importlib.import_module('reinforcement_learning_client_server')
% /Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/



% env = py.gym.make("CartPole-v0")

% action_space = Box(low=-1000, high=1000, shape=(2,), dtype=np.float)
% action_space = py.gym.spaces.Discrete(100)

% observation_space = py.gym.spaces.Box([-2000;-2000], [2000;2000]);
% 
% action_space = py.reinforcement_learning_client_server.action_space
% observation_space = py.reinforcement_learning_client_server.observation_space

disp(py.reinforcement_learning_client_server.FTTPowerEnvironment(1, 2))

% env = py.reinforcement_learning_client_server.FTTPowerEnvironment(1, 2)

client = py.ray.rllib.env.policy_client.PolicyClient('http://127.0.0.1:9900')

eid = client.start_episode()

obs = env.reset()
rewards = 0
% reward=0;
% done=false;
%   info=0;
while true
    action = client.get_action(eid, obs);

%     [obs, reward, done, info] = env.step(action)
    list = env.step(action)
    obs = list{1}
    reward = list{2}
    done = list{3}
    info = list{4}
    rewards = rewards + reward;
    client.log_returns(eid, reward, info)
    if done
        rewards
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

