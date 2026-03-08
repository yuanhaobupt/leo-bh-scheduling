classdef DQNAgent < handle
    % DQNAgent DQN Agent
    % Implements Deep Q-Network algorithm for satellite beam scheduling
    
    properties (Access = public)
        q_network          % Q network
        target_network     % Target network
        replay_buffer      % Experience replay buffer
        gamma             % Discount factor
        epsilon           % Current exploration rate
        epsilon_start     % Initial exploration rate
        epsilon_end       % Final exploration rate
        epsilon_decay     % Exploration rate decay steps
        learning_rate     % Learning rate
        batch_size       % Batch size
        target_update_freq % Target network update frequency
        update_step      % Update step count
        total_steps      % Total steps
    end
    
    methods
        function obj = DQNAgent(config)
            % Constructor
            %   config: Configuration struct containing:
            %       - state_size: State dimension
            %       - action_size: Action dimension
            %       - gamma: Discount factor (default 0.95)
            %       - epsilon_start: Initial exploration rate (default 1.0)
            %       - epsilon_end: Final exploration rate (default 0.1)
            %       - epsilon_decay: Exploration rate decay steps (default 10000)
            %       - learning_rate: Learning rate (default 1e-3)
            %       - batch_size: Batch size (default 32)
            %       - buffer_size: Experience buffer capacity (default 10000)
            %       - target_update_freq: Target network update frequency (default 200)
            
            % Set default parameters
            if nargin == 0
                config = struct();
            end
            
            if ~isfield(config, 'gamma')
                config.gamma = 0.95;
            end
            if ~isfield(config, 'epsilon_start')
                config.epsilon_start = 1.0;
            end
            if ~isfield(config, 'epsilon_end')
                config.epsilon_end = 0.3;
            end
            if ~isfield(config, 'epsilon_decay')
                config.epsilon_decay = 5000;
            end
            if ~isfield(config, 'learning_rate')
                config.learning_rate = 1e-3;
            end
            if ~isfield(config, 'batch_size')
                config.batch_size = 32;
            end
            if ~isfield(config, 'buffer_size')
                config.buffer_size = 10000;
            end
            if ~isfield(config, 'target_update_freq')
                config.target_update_freq = 200;
            end
            if ~isfield(config, 'state_size')
                config.state_size = 100;
            end
            if ~isfield(config, 'action_size')
                config.action_size = 1000;
            end
            
            % Initialize properties
            obj.gamma = config.gamma;
            obj.epsilon_start = config.epsilon_start;
            obj.epsilon_end = config.epsilon_end;
            obj.epsilon_decay = config.epsilon_decay;
            obj.learning_rate = config.learning_rate;
            obj.batch_size = config.batch_size;
            obj.target_update_freq = config.target_update_freq;
            obj.epsilon = obj.epsilon_start;
            obj.update_step = 0;
            obj.total_steps = 0;
            
            % Create networks
            obj.q_network = methods.DQN.DQNNetwork(...
                config.state_size, config.action_size, obj.learning_rate);
            obj.target_network = methods.DQN.DQNNetwork(...
                config.state_size, config.action_size, obj.learning_rate);
            
            % Create experience replay
            obj.replay_buffer = methods.DQN.ReplayBuffer(config.buffer_size);
            
            % Initialize target network
            obj.update_target();
            
            fprintf('[OK] DQN Agent created successfully\n');
            fprintf('    Discount factor: %.2f\n', obj.gamma);
            fprintf('    Learning rate: %.4f\n', obj.learning_rate);
            fprintf('    Batch size: %d\n', obj.batch_size);
            fprintf('    Exploration rate: %.2f -> %.2f (%d steps)\n', ...
                obj.epsilon_start, obj.epsilon_end, obj.epsilon_decay);
        end
        
        function action = select_action(obj, state, action_mask)
            % Select action using epsilon-greedy policy
            %   state: Current state
            %   action_mask: Action mask (optional, logical array, 1 means valid action)
            %   action: Selected action
            
            if nargin < 3
                action_mask = [];
            end
            
            if rand < obj.epsilon
                % Random exploration
                if ~isempty(action_mask)
                    valid_actions = find(action_mask);
                    if isempty(valid_actions)
                        action = randi(obj.q_network.output_size);
                    else
                        action = valid_actions(randi(length(valid_actions)));
                    end
                else
                    action = randi(obj.q_network.output_size);
                end
            else
                % Greedy exploitation
                q_values = obj.q_network.predict(state);
                
                if ~isempty(action_mask)
                    q_values(~action_mask) = -inf;
                end
                
                [~, action] = max(q_values);
            end
        end
        
        function train_step(obj)
            % Train one step (sample from experience buffer and update network)
            
            if obj.replay_buffer.get_size < obj.batch_size
                return;
            end
            
            % Sample mini-batch
            batch = obj.replay_buffer.sample(obj.batch_size);
            
            if isempty(batch)
                return;
            end
            
            % Update Q network
            % Note: This uses a simplified implementation
            % In practice, gradient descent should be used
            obj.q_network.update(batch, obj.gamma, obj.target_network);
            
            % Update exploration rate
            obj.epsilon = max(obj.epsilon_end, ...
                obj.epsilon_start - (obj.epsilon_start - obj.epsilon_end) * ...
                obj.update_step / obj.epsilon_decay);
            obj.update_step = obj.update_step + 1;
            obj.total_steps = obj.total_steps + 1;
            
            % Periodically update target network
            if mod(obj.update_step, obj.target_update_freq) == 0
                obj.update_target();
            end
        end
        
        function update_target(obj)
            % Update target network (soft update or hard update)
            % Here we use hard update
            obj.target_network.net = obj.q_network.net;
        end
        
        function store_experience(obj, state, action, reward, next_state, done)
            % Store experience to replay buffer
            %   state: Current state
            %   action: Action taken
            %   reward: Reward received
            %   next_state: Next state
            %   done: Whether terminated
            
            obj.replay_buffer.add(state, action, reward, next_state, done);
        end
        
        function save_agent(obj, filename)
            % Save agent
            %   filename: Save filename
            
            save(filename, 'obj', '-v7.3');
            fprintf('[OK] Agent saved to: %s\n', filename);
        end
        
        function load_agent(obj, filename)
            % Load agent
            %   filename: Agent filename
            
            try
                data = load(filename);
                obj = data.obj;
                fprintf('[OK] Agent loaded from: %s\n', filename);
            catch ME
                error('[ERROR] Agent load failed: %s', ME.message);
            end
        end
        
        function display_info(obj)
            % Display agent information
            fprintf('=== DQNAgent Info ===\n');
            fprintf('Total steps: %d\n', obj.total_steps);
            fprintf('Update steps: %d\n', obj.update_step);
            fprintf('Current exploration rate: %.4f\n', obj.epsilon);
            fprintf('Experience buffer size: %d/%d\n', ...
                obj.replay_buffer.get_size, obj.replay_buffer.capacity);
        end
    end
end
