classdef DQNNetwork < handle
    % DQNNetwork DQN Neural Network
    % Used to estimate state-action value function (Q-values)
    
    properties (Access = public)
        net             % Neural network
        input_size      % Input dimension
        output_size     % Output dimension
        learning_rate   % Learning rate
    end
    
    methods
        function obj = DQNNetwork(input_size, output_size, learning_rate)
            % Constructor
            %   input_size: Input state dimension
            %   output_size: Output action dimension
            %   learning_rate: Learning rate (default 1e-3)
            
            if nargin == 0
                input_size = 100;
                output_size = 1000;
                learning_rate = 1e-3;
            end
            
            obj.input_size = input_size;
            obj.output_size = output_size;
            obj.learning_rate = learning_rate;
            
            % Create network (simple structure)
            % Use fully connected layers
            layers = [
                featureInputLayer(input_size, 'Name', 'state', 'Normalization', 'none')
                fullyConnectedLayer(256, 'Name', 'fc1')
                leakyReluLayer(0.01, 'Name', 'lrelu1')
                dropoutLayer(0.1, 'Name', 'dropout1')
                fullyConnectedLayer(128, 'Name', 'fc2')
                leakyReluLayer(0.01, 'Name', 'lrelu2')
                dropoutLayer(0.1, 'Name', 'dropout2')
                fullyConnectedLayer(output_size, 'Name', 'output')
            ];
            
            % Create network
            try
                obj.net = dlnetwork(layers);
                fprintf('[OK] DQN Network created successfully\n');
                fprintf('    Input dimension: %d\n', input_size);
                fprintf('    Output dimension: %d\n', output_size);
                fprintf('    Learning rate: %.4f\n', learning_rate);
            catch ME
                error('[ERROR] DQN Network creation failed: %s', ME.message);
            end
        end
        
        function q_values = predict(obj, state)
            % Forward propagation, return Q-values
            %   state: Input state (can be single state or batch)
            %   q_values: Corresponding Q-values
            
            try
                q_values = predict(obj.net, state);
            catch ME
                warning('Prediction failed: %s', ME.message);
                q_values = zeros(obj.output_size, 1);
            end
        end
        
        function loss = compute_loss(obj, states, actions, rewards, next_states, dones, gamma, target_net)
            % Compute DQN loss (TD error)
            %   states: Current state batch
            %   actions: Action batch
            %   rewards: Reward batch
            %   next_states: Next state batch
            %   dones: Termination flag batch
            %   gamma: Discount factor
            %   target_net: Target network
            %   loss: Average TD error
            
            % Calculate current Q-values
            current_q_values = obj.predict(states);
            
            % Calculate target Q-values
            next_q_values = target_net.predict(next_states);
            max_next_q = max(next_q_values, [], 1);
            target_q = rewards + gamma * (1 - dones) .* max_next_q;
            
            % Extract Q-values for corresponding actions
            batch_size = length(actions);
            indices = sub2ind(size(current_q_values), actions, 1:batch_size);
            current_q = current_q_values(indices);
            
            % Calculate loss (MSE)
            loss = mean((current_q - target_q).^2);
        end
        
        function update(obj, batch, gamma, target_net)
            % Update network using gradient descent (simplified version)
            % Note: This uses a simplified implementation
            % In practice, a more complete training loop should be used
            
            if isempty(batch)
                return;
            end
            
            % Extract data from batch
            states = cat(2, batch.state);
            actions = cat(2, batch.action);
            rewards = cat(2, batch.reward);
            next_states = cat(2, batch.next_state);
            dones = cat(2, batch.done);
            
            % Calculate gradients and update (simplified)
            % In practice, trainNetwork or automatic differentiation should be used
            try
                % Here we use a simplified update method
                % Actual training should be done in DQNAgent
                
                % Temporarily only print information
                % Actual training should be in DQNAgent
                
            catch ME
                warning('Network update failed: %s', ME.message);
            end
        end
        
        function save_model(obj, filename)
            % Save model
            %   filename: Save filename
            
            try
                save(filename, 'obj.net', 'obj.input_size', 'obj.output_size', 'obj.learning_rate', '-v7.3');
                fprintf('[OK] Model saved to: %s\n', filename);
            catch ME
                error('[ERROR] Model save failed: %s', ME.message);
            end
        end
        
        function load_model(obj, filename)
            % Load model
            %   filename: Model filename
            
            try
                data = load(filename);
                obj.net = data.obj.net;
                obj.input_size = data.obj.input_size;
                obj.output_size = data.obj.output_size;
                obj.learning_rate = data.obj.learning_rate;
                fprintf('[OK] Model loaded from: %s\n', filename);
            catch ME
                error('[ERROR] Model load failed: %s', ME.message);
            end
        end
    end
end
