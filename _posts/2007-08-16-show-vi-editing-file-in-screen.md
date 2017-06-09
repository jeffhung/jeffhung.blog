# 在 screen 裡顯示 vi 正在編輯的檔案

Rafan 在問，[怎樣在 screen 裡顯示 ssh 出去的 hostname](http://blog.rafan.org/archives/145)。這個以前我有搞過類似的：在 screen 裡顯示 vi 正在編輯的檔案。

#### 怎樣使用 screen 的 shelltitle 功能

Screen 可以利用 shelltitle 功能，只要畫面上出現規定的 pattern，就可以抓取其中指定的區域，當作 shell window 的 title。Screen 的 manpage 是這麼說的：

```
TITLES (naming windows)
You can customize each window's name in the window display (viewed with
the "windows" command (C-a w)) by setting it with one of the title com-
mands.  Normally the name displayed is the actual command name  of  the
program created in the window.  However, it is sometimes useful to dis-
tinguish various programs of the same name or to change  the  name  on-
the-fly to reflect the current state of the window.

The default name for all shell windows can be set with the "shelltitle"
command in the .screenrc file, while all other windows are created with
a "screen" command and thus can have their name set with the -t option.
Interactively,    there    is    the    title-string    escape-sequence
(<esc>kname<esc>\)  and the "title" command (C-a A).  The former can be
output from an application to control the window's name under  software
control,  and  the  latter  will prompt for a name when typed.  You can
also bind pre-defined names to keys with the  "title"  command  to  set
things quickly without prompting.

Finally,  screen has a shell-specific heuristic that is enabled by set-g
ting the window's name to "search|name" and arranging to  have  a  nullg
title escape-sequence output as a part of your prompt.  The search por-g
tion specifies an end-of-prompt search string, while the  name  portiong
specifies the default shell name for the window.  If the name ends in ag
`:' screen will add what it believes to be the current command  runningg
in  the window to the end of the window's shell name (e.g. "name:cmd").g
Otherwise the current command name supersedes the shell name  while  itg
is running.g
```

意思是說，在 `~/.screenrc` 裡面，我們可以設定	`shelltitle` 變數為 `search|name`，screen 會在所有螢幕上顯示的東西裡，尋找 `<esc>k<esc>\search` 的 pattern，如果找到了，就會以之為起點，尋找在這個 pattern 之後，應該是屬於 command 的部份，然後顯示於 title 上。通常來說，是擷取從 `<esc>k<esc>\search` 開始，到第一個空白之前的 pattern，如果找不到，就會以 `name` 顯示。

由於我習慣使用 TCSH，prompt 用 "`% `" 符號 (在 `%` 之後，多加了一個空白，比較好看些。)，所以我把 `shelltitle` 設定成：

```
shelltitle '% |TCSH'
```

然後在 `~/.cshrc` 裡，將 prompt 設定成：

```
set prompt = "%{\ek\e\\%}%% "
```

這樣一來，例如在執行 `top` 這類程式時，就可以在 screen 的 window title 上看出來，是哪一個 window 在跑 `top`。

#### 怎樣改讓 screen 顯示 vi 正在編輯的檔案

同理，我們可以寫一個前導程式，在啟動 vi 之前，先顯示 screen shelltitle 的字樣，然後才啟動 vi，這樣就可以讓 screen 在 window title 上，顯示出 vi 正在編輯的檔名。程式叫 `svi.sh`，如下：

```shell
usage()
{
    echo "Usage: svi.sh <file>";
    echo "";
    echo "Launch vi to edit <file> and show <file> name on screen(1)'s";
    echo "shelltitle for easy switching.";
    echo "";
}

#
# Find first non-option argument.
#
__shell_title='';
for arg in $@; do
    case "$arg" in
    -*) # do nothing to option argument
        ;;
    *)  # save first non-option argument
        if [ -z $__shell_title ]; then
            __shell_title="$arg";
        fi;
        ;;
    esac;
done;

svi_editor__=${EDITOR:=vi};
if [ -z $__shell_title ]; then
    __shell_title=$svi_editor__;
fi;
printf '\033k\033\\%% [%s]%s\n' \
       `echo $svi_editor__ | env-shelltitle-fix.pl` \
       "$__shell_title";
$svi_editor__ $@;
unset svi_editor__;
unset __shell_title;
```

這個前導程式做的事情很簡單，就是尋訪一遍 command-line 參數，跳過 option 參數，取第一個非 option 的參數，通常這就是 vi 要編輯的檔名<span class="footnote">我沒有抓 basename，抓了應該會更好看些。</span>。假設這個檔名叫做 `foo.cpp`，screen 的 window title 就會顯示成 `[vi]foo.cpp`。邏輯如下：

利用 screen 的 shelltitle 的功能，在執行 vi 之前，先印出 `\033k\033\\%% [<em>vi</em>]<em>filename</em>`，其中，`vi` 會被代換為環境變數 `EDITOR` 所指定的編輯器，如果沒有這個環境變數的話，就直接用 `vi`。這裡要注意的是，`[vi]` 與 `filename` 之間不可以有空白，因為 screen 的 shelltitle 取的就是 `\033k\033\\%%` 後，再下一個空白之前的 token。

最後，因為有時候 `EDITOR` 環境變數，會被 alias 誠如會被 alias 成如 `env LC_CTYPE=ISO8859-1 vi` 的樣子，故多加了一個 `env-shelltitle-fix.pl` 把 env 的部份去掉。這部份其實寫的很爛，不過勉強可用。

最後，把 `vi` 指令給 `alias` 成 `svi.sh`，然後把 `svi.sh` 放到 `PATH` 環境目錄所列出來的目錄下即可。

#### 後記

雖然讓 screen 的 window title 顯示 vi 目前正在編輯的檔名，很酷也很方便，不過在 vim7 支援 tab 之後，從 [SDI](http://en.wikipedia.org/wiki/Single_document_interface) 變成 [MDI](http://en.wikipedia.org/wiki/Multiple_document_interface)，這個功能就沒什麼意義了。一來，因為一個 vi 同時編輯很多個檔案，顯示第一個被編輯的檔案，根本沒有意義；二來，此時 vi 的功能，已經接近一個完整的 [IDE](http://en.wikipedia.org/wiki/Integrated_development_environment) 了，只需要另外再搭配一個 shell window，就夠方便了。所以，後來我就沒有再繼續使用 `svi.sh` 這一招了。

