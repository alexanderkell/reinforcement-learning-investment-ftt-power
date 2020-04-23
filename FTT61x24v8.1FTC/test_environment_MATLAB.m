
% pyenv('Version','/Users/alexanderkell/.pyenv/shims/python3')


import ray.rllib.env.policy_client.*


env = py.gym.make("CartPole-v0")

client = py.ray.rllib.env.policy_client.PolicyClient('http://localhost:9900');

eid = client.start_episode()

obs = env.reset()
rewards = 0

while true
    action = client.get_action(eid, obs);
    [obs, reward, done, info] = env.step(action);
    
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

