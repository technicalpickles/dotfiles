function fish_greeting
  if type welcome2u >/dev/null 2>&1
    welcome2u
  else if test -d ~/workspace/fancy-motd
    # fancy-motd uses `declare -A`, which isn't available on the default macOS bash (3.2.57)
    # seems it is 4.0+? https://github.com/bminor/bash/blob/f3b6bd19457e260b65d11f2712ec3da56cef463f/CHANGES#L5262-L5263
    set bash (brew --prefix bash)
    if test -n "$bash"
      $bash/bin/bash ~/workspace/fancy-motd/motd.sh
    end
  end
end

