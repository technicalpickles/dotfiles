function ghostty-theme --description 'Hot-swap the current Ghostty window to a theme from ~/.config/ghostty/themes via OSC (or "reset")'
    if test (count $argv) -eq 0
        echo "usage: ghostty-theme <name|reset>   (e.g. catppuccin-mocha)" >&2
        return 1
    end

    if test "$argv[1]" = reset
        printf '\e]104\a\e]110\a\e]111\a\e]112\a\e]117\a\e]119\a'
        return 0
    end

    set -l name (string replace -r '\.conf$' '' -- $argv[1])
    set -l file ~/.config/ghostty/themes/$name.conf
    if not test -f $file
        echo "ghostty-theme: no such theme: $file" >&2
        return 1
    end

    for line in (cat $file)
        set -l m (string match -r '^\s*([a-z-]+)\s*=\s*(.+?)\s*$' -- $line)
        or continue
        set -l key $m[2]
        set -l val $m[3]

        switch $key
            case palette
                set -l p (string split -m1 = -- $val)
                printf '\e]4;%s;%s\a' $p[1] (string replace -r '^#?' '#' -- $p[2])
            case background
                printf '\e]11;%s\a' (string replace -r '^#?' '#' -- $val)
            case foreground
                printf '\e]10;%s\a' (string replace -r '^#?' '#' -- $val)
            case cursor-color
                printf '\e]12;%s\a' (string replace -r '^#?' '#' -- $val)
            case selection-background
                printf '\e]17;%s\a' (string replace -r '^#?' '#' -- $val)
            case selection-foreground
                printf '\e]19;%s\a' (string replace -r '^#?' '#' -- $val)
        end
    end
end
