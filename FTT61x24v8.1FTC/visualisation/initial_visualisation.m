% One investment
% output = load('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/data/outputs/output482000.000000.mat');
% Every year investment
output = load('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/raw_data/output_7-every-year-investments-50000.000000.mat')
capacity = output.output.U;

elec_generated = output.output.G;

demand = output.output.D;

carbon_emissions = output.output.E;

LCOE = output.output.LCOE;

% test = output.ouput.Test;

class(capacity)
% plotmatrix(capacity)

market_share = output.output.S;

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/market_share.csv', market_share);

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/capacity_result.csv', capacity);

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/electricity_generated.csv', elec_generated);

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/carbon_emissions.csv', carbon_emissions);
 
csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/LCOE.csv', LCOE);

csvwrite('/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/data/outputs/demand.csv', demand);


uk_capacity = capacity(:,:,1);

% plot(elec_generated(:,:,1)) 

% plot(carbon_emissions(:,:,2))

plot(demand(:,:,1))