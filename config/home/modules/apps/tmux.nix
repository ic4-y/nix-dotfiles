{ pkgs, ... }:
{
  # tmux
  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.resurrect
      unstable.tmuxPlugins.sensible
      unstable.tmuxPlugins.yank
      unstable.tmuxPlugins.resurrect
      unstable.tmuxPlugins.continuum
      unstable.tmuxPlugins.tmux-thumbs
      unstable.tmuxPlugins.tmux-fzf
      unstable.tmuxPlugins.catppuccin
    ];
  };

  #tmux conf
  home.file.".tmux.conf" = {
    executable = false;
    text = ''
      # TMUX RESET
      # First remove *all* keybindings
      # unbind-key -a
      # Now reinsert all the regular tmux keys
      bind ^X lock-server
      bind ^C new-window -c "$HOME"
      bind ^D detach
      bind * list-clients

      bind H previous-window
      bind L next-window

      bind r command-prompt "rename-window %%"
      bind R source-file ~/.config/tmux/tmux.conf
      bind ^A last-window
      bind ^W list-windows
      bind w list-windows
      bind z resize-pane -Z
      bind ^L refresh-client
      bind l refresh-client
      bind | split-window
      bind s split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind '"' choose-window
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r -T prefix , resize-pane -L 20
      bind -r -T prefix . resize-pane -R 20
      bind -r -T prefix - resize-pane -D 7
      bind -r -T prefix = resize-pane -U 7
      bind : command-prompt
      bind * setw synchronize-panes
      bind P set pane-border-status
      bind c kill-pane
      bind x swap-pane -D
      bind S choose-session
      bind R source-file ~/.config/tmux/tmux.conf
      bind K send-keys "clear"\; send-keys "Enter"
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # REGULAR TMUX CONFIG
      set-option -g default-terminal 'screen-254color'
      set-option -g terminal-overrides ',xterm-256color:RGB'

      set -g prefix ^A
      set -g base-index 0
      set -g detach-on-destroy off     # don't exit from tmux when closing a session
      set -g escape-time 0             # zero-out escape time delay
      set -g history-limit 2000
      set -g renumber-windows on       # renumber all windows when any window is closed
      set -g set-clipboard on          # use system clipboard
      set -g status-position top       # macOS / darwin style
      set -g default-terminal foot
      setw -g mode-keys vi
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'

      set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
      set -g @fzf-url-history-limit '2000'

      # set -g @plugin 'tmux-plugins/tmux-sensible'
      # set -g @plugin 'tmux-plugins/tmux-yank'
      # set -g @plugin 'tmux-plugins/tmux-resurrect'
      # set -g @plugin 'tmux-plugins/tmux-continuum'
      # set -g @plugin 'fcsonline/tmux-thumbs'
      # set -g @plugin 'sainnhe/tmux-fzf'
      # set -g @plugin 'wfxr/tmux-fzf-url'
      # set -g @plugin 'catppuccin/tmux'

      # set -g @sessionx-bind 'o'
      # set -g @sessionx-x-path '~/dotfiles'
      # set -g @sessionx-window-height '85%'
      # set -g @sessionx-window-width '75%'
      # set -g @sessionx-zoxide-mode 'on'
      # set -g @sessionx-filter-current 'false'
      # set -g @sessionx-preview-enabled 'true'
      set -g @continuum-restore 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @catppuccin_window_left_separator ""
      set -g @catppuccin_window_right_separator " "
      set -g @catppuccin_window_middle_separator " █"
      set -g @catppuccin_window_number_position "right"
      set -g @catppuccin_window_default_fill "number"
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_fill "number"
      set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
      set -g @catppuccin_status_modules_right "directory meetings date_time"
      set -g @catppuccin_status_modules_left "session"
      set -g @catppuccin_status_left_separator  " "
      set -g @catppuccin_status_right_separator " "
      set -g @catppuccin_status_right_separator_inverse "no"
      set -g @catppuccin_status_fill "icon"
      set -g @catppuccin_status_connect_separator "no"
      set -g @catppuccin_directory_text "#{b:pane_current_path}"
      # set -g @catppuccin_meetings_text "#($HOME/.config/tmux/scripts/cal.sh)"
      set -g @catppuccin_date_time_text "%H:%M"

      # run '~/.tmux/plugins/tpm/tpm'
    '';
  };
}
