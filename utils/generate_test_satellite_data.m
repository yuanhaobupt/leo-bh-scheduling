function generate_test_satellite_data()
% GENERATE_TEST_SATELLITE_DATA Generate synthetic satellite orbit data for testing
%
% This function creates a simple satellite orbit data file for testing purposes.
% For actual simulations, use real STK-generated orbit data.
%
% Output:
%   Creates '5400.mat' file with synthetic satellite positions

fprintf('Generating test satellite orbit data...\n');

% Configuration
num_satellites = 54;        % Number of satellites
altitude = 508e3;           % Orbital altitude (m)
earth_radius = 6371.393e3;  % Earth radius (m)
orbital_period = 5683;      % Orbital period (s)
time_step = 1;              % Time step (s)
total_steps = orbital_period + 1;

% Generate satellite positions
% Note: This is a simplified model for testing only
% Real data should come from STK simulations

LLAresult = zeros(num_satellites, total_steps, 2);

% Create circular orbits at different inclinations
for sat = 1:num_satellites
    % Distribute satellites across orbital planes
    plane = floor((sat-1) / 9);  % 6 orbital planes
    sat_in_plane = mod(sat-1, 9);
    
    % Orbital parameters
    inclination = 53 + plane * 5;  % degrees
    raan = plane * 60;             % Right ascension of ascending node (degrees)
    
    for step = 1:total_steps
        % Calculate position in orbit
        time = (step - 1) * time_step;
        mean_anomaly = mod(2 * pi * time / orbital_period + sat_in_plane * (2*pi/9), 2*pi);
        
        % Simplified circular orbit calculation
        % Convert to longitude and latitude
        lat = asin(sin(inclination * pi/180) * sin(mean_anomaly)) * 180/pi;
        lon = mod(raan + atan2(cos(inclination * pi/180) * sin(mean_anomaly), ...
                               cos(mean_anomaly)) * 180/pi + 180, 360) - 180;
        
        LLAresult(sat, step, 1) = lon;
        LLAresult(sat, step, 2) = lat;
    end
end

% Save to file
save('5400.mat', 'LLAresult');

fprintf('Test data generated successfully!\n');
fprintf('  - Number of satellites: %d\n', num_satellites);
fprintf('  - Total time steps: %d\n', total_steps);
fprintf('  - Orbital period: %d seconds\n', orbital_period);
fprintf('  - File saved: 5400.mat\n\n');
fprintf('Note: This is synthetic data for testing only.\n');
fprintf('For actual simulations, use real STK-generated orbit data.\n\n');

end
