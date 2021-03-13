oinfo = rlNumericSpec([1 1]);
oinfo.Name = 'Add Numbers States';
oinfo.Description = 'reward';

ActionInfo = rlFiniteSetSpec([2 1]);
ActionInfo.Name = 'Add Numbers Action';

resetHandle = @myResetFunction;
StepHandle = @(Action,LoggedSignals) myStepFunction(Action,LoggedSignals);

disp(oinfo)
whos oinfo

disp([0;0])
% ndims(([0 0]))

env = rlFunctionEnv(oinfo,ActionInfo,StepHandle,resetHandle);

% create a critic network to be used as underlying approximator
statePath = [
    sequenceInputLayer(1,'Name','seqState')
    fullyConnectedLayer(24, 'Name', 'CriticStateFC1')
    reluLayer('Name', 'CriticRelu1')
    fullyConnectedLayer(24, 'Name', 'CriticStateFC2')];
actionPath = [
    sequenceInputLayer(2,'Name','seqAction')
    fullyConnectedLayer(24, 'Name', 'CriticActionFC1')];
commonPath = [
    additionLayer(2,'Name', 'add')
    reluLayer('Name','CriticCommonRelu')
    fullyConnectedLayer(1, 'Name', 'output')];
criticNetwork = layerGraph(statePath);
criticNetwork = addLayers(criticNetwork, actionPath);
criticNetwork = addLayers(criticNetwork, commonPath);    
criticNetwork = connectLayers(criticNetwork,'CriticStateFC2','add/in1');
criticNetwork = connectLayers(criticNetwork,'CriticActionFC1','add/in2');

% set some options for the critic
criticOpts = rlRepresentationOptions('LearnRate',0.01,'GradientThreshold',1);

% create the critic based on the network approximator
critic = rlQValueRepresentation(criticNetwork,oinfo,ActionInfo, 'Observation',{'seqState'},'Action',{'seqAction'},criticOpts);

agentOpts = rlDQNAgentOptions('UseDoubleDQN',false, 'TargetUpdateMethod',"periodic", 'TargetUpdateFrequency',4, 'ExperienceBufferLength',100000, 'DiscountFactor',0.99,'MiniBatchSize',256);

agent = rlDQNAgent(critic,agentOpts)

getAction(agent,{rand(4,1)})


function [Observation,Reward,IsDone,LoggedSignals] = myStepFunction(Action,LoggedSignals)
    Observation = Action + Action;
    disp(Observation)
    Reward = Observation;
%     if Reward == 20
%         IsDone = 1;
%     else
%         IsDone = 0;
%     end
    IsDone = 0
    LoggedSignals.State = Reward;
    
end

function [InitialObservation, LoggedSignal] = myResetFunction()
    % Return initial environment state variables as logged signals.
    LoggedSignal.State = [0];
    InitialObservation = LoggedSignal.State;

end


