fun! s:DetectRuby()
    if getline(1) == '#!/usr/bin/env shell-ruby'
        set filetype=ruby
    endif

    if getline(1) == '#!/usr/bin/env safe-ruby'
        set filetype=ruby
    endif
endfun

autocmd BufRead */shell/bin/* call s:DetectRuby()
autocmd BufRead */github/script/* call s:DetectRuby()
