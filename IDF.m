clear all
clc

% Read hourly rainfall time series from a CSV file

Data = readtable("data.csv");

date = Data.Var1;
DTN=datevec(date);

year_int = min(DTN(:,1));
year_final = max(DTN(:,1));

% Define the Durations

Sliding_Window = [1 2 4 6 12 24];

for k = 1:length(Sliding_Window)
    x = Data.Rain;
    x(isnan(x))=0;
    y = movsum(x,Sliding_Window(k));
    cumm_data{1,k} = y;
end

clear x y
for k = 1:length(Sliding_Window)
    for year = year_int:year_final
        x = cumm_data{1,k};
        y = x(DTN(:,1)==year);
        cumm_data_rearranged{k,1}(1:length(y),year-year_int+1)=y;
    end
end

for k = 1:length(Sliding_Window)
    for year = year_int:year_final
        ams(k,year-year_int+1) =max(cumm_data_rearranged{k,1}(:,year-year_int+1));
    end
end

% % Define the return periods

return_period = [2, 5, 10, 25, 50, 100];

for k = 1:length(return_period)
    cdf(k) = 1 - (1/return_period(k));
end

for k = 1:length(Sliding_Window)
    param{k,1} = gevfit(ams(k,:));
end

for i = 1:length(Sliding_Window)
    for j =1:length(return_period)

        k = param{i,1}(1,1);
        sigma = param{i,1}(1,2);
        mu = param{i,1}(1,3);
    
        quantile(i,j) = gevinv(cdf(j), k, sigma, mu);
    end
end

for i = 1:length(Sliding_Window)
    for j =1:length(return_period)
        Intensity(i,j) = quantile(i,j)/ Sliding_Window(i);
    end
end

% Define the return periods for the legend.
returnPeriods = [2, 5, 10, 25, 50, 100];

% Create a figure with specified properties.
figure('MenuBar', 'none', 'Name', 'IDF Curves', 'NumberTitle', 'off');

% Loop through the intensity data and plot each curve.
for j = 1:size(Intensity, 2) % Use size(Intensity, 2) to dynamically handle the number of columns
    plot(Sliding_Window, Intensity(:, j), 'LineWidth', 2); % Increase linewidth for better visibility

    % Add labels and grid within the loop (optional but cleaner).
    if j == 1 % Only add labels and grid once.
        xlabel('Duration (hours)', 'FontSize', 12);
        ylabel('Intensity (mm/hr)', 'FontSize', 12);
        grid on;
        set(gca, 'FontSize', 12); % Set axis font size.
    end

    hold on; % Keep adding plots to the same figure.
end

% Create the legend with the return periods.
legend(strcat('T = ', string(returnPeriods), '-Year'), 'Location', 'best'); % Use string concatenation for clarity.

% Optionally, adjust plot appearance for better presentation.
hold off; % Release the hold on the plot.
set(gcf, 'Color', 'white'); % Set figure background to white.

