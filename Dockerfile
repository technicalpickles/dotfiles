FROM ubuntu:latest

RUN apt-get update \
  && apt-get install -y curl software-properties-common \
  && add-apt-repository ppa:fish-shell/release-4 \
  && apt-get update \
  && apt-get install -y fish git-core
SHELL ["/usr/bin/fish", "-c"]
RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
RUN fisher install IlanCosman/tide@v6 && tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Vertical --powerline_prompt_heads=Round --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=Yes

CMD ["/usr/bin/fish"]
WORKDIR /root
