output = load('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/data/outputs/output181000.000000.mat')

capacity = output.output.U

class(capacity)
% plotmatrix(capacity)

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/capacity_result.csv', capacity)

uk_capacity = capacity(:,:,1);

% plot(uk_capacity) 