#!bash
#
# bash/zsh completion support for core Git.
#
# Copyright (C) 2006,2007 Shawn O. Pearce <spearce@spearce.org>
# Conceptually based on gitcompletion (http://gitweb.hawaga.org.uk/).
# Distributed under the GNU General Public License, version 2.0.
#
# The contained completion routines provide support for completing:
#
#    *) local and remote branch names
#    *) local and remote tag names
#    *) .git/remotes file names
#    *) git 'subcommands'
#    *) tree paths within 'ref:path/to/file' expressions
#    *) file paths within current working directory and index
#    *) common --long-options
#
# To use these routines:
#
#    1) Copy this file to somewhere (e.g. ~/.git-completion.sh).
#    2) Add the following line to your .bashrc/.zshrc:
#        source ~/.git-completion.sh
#    3) Consider changing your PS1 to also show the current branch,
#       see git-prompt.sh for details.

case "$COMP_WORDBREAKS" in
*:*) : great ;;
*)   COMP_WORDBREAKS="$COMP_WORDBREAKS:"
esac

# __gitdir accepts 0 or 1 arguments (i.e., location)
# returns location of .git repo
__gitdir ()
{
	# Note: this function is duplicated in git-prompt.sh
	# When updating it, make sure you update the other one to match.
	if [ -z "${1-}" ]; then
		if [ -n "${__git_dir-}" ]; then
			echo "$__git_dir"
		elif [ -n "${GIT_DIR-}" ]; then
			test -d "${GIT_DIR-}" || return 1
			echo "$GIT_DIR"
		elif [ -d .git ]; then
			echo .git
		else
			git rev-parse --git-dir 2>/dev/null
		fi
	elif [ -d "$1/.git" ]; then
		echo "$1/.git"
	else
		echo "$1"
	fi
}

__gitcomp_1 ()
{
	local c IFS=$' \t\n'
	for c in $1; do
		c="$c$2"
		case $c in
		--*=*|*.) ;;
		*) c="$c " ;;
		esac
		printf '%s\n' "$c"
	done
}

# The following function is based on code from:
#
#   bash_completion - programmable completion functions for bash 3.2+
#
#   Copyright © 2006-2008, Ian Macdonald <ian@caliban.org>
#             © 2009-2010, Bash Completion Maintainers
#                     <bash-completion-devel@lists.alioth.debian.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#   The latest version of this software can be obtained here:
#
#   http://bash-completion.alioth.debian.org/
#
#   RELEASE: 2.x

# This function can be used to access a tokenized list of words
# on the command line:
#
#	__git_reassemble_comp_words_by_ref '=:'
#	if test "${words_[cword_-1]}" = -w
#	then
#		...
#	fi
#
# The argument should be a collection of characters from the list of
# word completion separators (COMP_WORDBREAKS) to treat as ordinary
# characters.
#
# This is roughly equivalent to going back in time and setting
# COMP_WORDBREAKS to exclude those characters.  The intent is to
# make option types like --date=<type> and <rev>:<path> easy to
# recognize by treating each shell word as a single token.
#
# It is best not to set COMP_WORDBREAKS directly because the value is
# shared with other completion scripts.  By the time the completion
# function gets called, COMP_WORDS has already been populated so local
# changes to COMP_WORDBREAKS have no effect.
#
# Output: words_, cword_, cur_.

__git_reassemble_comp_words_by_ref()
{
	local exclude i j first
	# Which word separators to exclude?
	exclude="${1//[^$COMP_WORDBREAKS]}"
	cword_=$COMP_CWORD
	if [ -z "$exclude" ]; then
		words_=("${COMP_WORDS[@]}")
		return
	fi
	# List of word completion separators has shrunk;
	# re-assemble words to complete.
	for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++)); do
		# Append each nonempty word consisting of just
		# word separator characters to the current word.
		first=t
		while
			[ $i -gt 0 ] &&
			[ -n "${COMP_WORDS[$i]}" ] &&
			# word consists of excluded word separators
			[ "${COMP_WORDS[$i]//[^$exclude]}" = "${COMP_WORDS[$i]}" ]
		do
			# Attach to the previous token,
			# unless the previous token is the command name.
			if [ $j -ge 2 ] && [ -n "$first" ]; then
				((j--))
			fi
			first=
			words_[$j]=${words_[j]}${COMP_WORDS[i]}
			if [ $i = $COMP_CWORD ]; then
				cword_=$j
			fi
			if (($i < ${#COMP_WORDS[@]} - 1)); then
				((i++))
			else
				# Done.
				return
			fi
		done
		words_[$j]=${words_[j]}${COMP_WORDS[i]}
		if [ $i = $COMP_CWORD ]; then
			cword_=$j
		fi
	done
}

if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
_get_comp_words_by_ref ()
{
	local exclude cur_ words_ cword_
	if [ "$1" = "-n" ]; then
		exclude=$2
		shift 2
	fi
	__git_reassemble_comp_words_by_ref "$exclude"
	cur_=${words_[cword_]}
	while [ $# -gt 0 ]; do
		case "$1" in
		cur)
			cur=$cur_
			;;
		prev)
			prev=${words_[$cword_-1]}
			;;
		words)
			words=("${words_[@]}")
			;;
		cword)
			cword=$cword_
			;;
		esac
		shift
	done
}
fi

# Generates completion reply with compgen, appending a space to possible
# completion words, if necessary.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word (optional).
__gitcomp ()
{
	local cur_="${3-$cur}"

	case "$cur_" in
	--*=)
		COMPREPLY=()
		;;
	*)
		local IFS=$'\n'
		COMPREPLY=($(compgen -P "${2-}" \
			-W "$(__gitcomp_1 "${1-}" "${4-}")" \
			-- "$cur_"))
		;;
	esac
}

# Generates completion reply with compgen from newline-separated possible
# completion words by appending a space to all of them.
# It accepts 1 to 4 arguments:
# 1: List of possible completion words, separated by a single newline.
# 2: A prefix to be added to each possible completion word (optional).
# 3: Generate possible completion matches for this word (optional).
# 4: A suffix to be appended to each possible completion word instead of
#    the default space (optional).  If specified but empty, nothing is
#    appended.
__gitcomp_nl ()
{
	local IFS=$'\n'
	COMPREPLY=($(compgen -P "${2-}" -S "${4- }" -W "$1" -- "${3-$cur}"))
}

# Generates completion reply with compgen from newline-separated possible
# completion filenames.
# It accepts 1 to 3 arguments:
# 1: List of possible completion filenames, separated by a single newline.
# 2: A directory prefix to be added to each possible completion filename
#    (optional).
# 3: Generate possible completion matches for this word (optional).
__gitcomp_file ()
{
	local IFS=$'\n'

	# XXX does not work when the directory prefix contains a tilde,
	# since tilde expansion is not applied.
	# This means that COMPREPLY will be empty and Bash default
	# completion will be used.
	COMPREPLY=($(compgen -P "${2-}" -W "$1" -- "${3-$cur}"))

	# Tell Bash that compspec generates filenames.
	compopt -o filenames 2>/dev/null
}

__git_index_file_list_filter_compat ()
{
	local path

	while read -r path; do
		case "$path" in
		?*/*) echo "${path%%/*}/" ;;
		*) echo "$path" ;;
		esac
	done
}

__git_index_file_list_filter_bash ()
{
	local path

	while read -r path; do
		case "$path" in
		?*/*)
			# XXX if we append a slash to directory names when using
			# `compopt -o filenames`, Bash will append another slash.
			# This is pretty stupid, and this the reason why we have to
			# define a compatible version for this function.
			echo "${path%%/*}" ;;
		*)
			echo "$path" ;;
		esac
	done
}

# Process path list returned by "ls-files" and "diff-index --name-only"
# commands, in order to list only file names relative to a specified
# directory, and append a slash to directory names.
__git_index_file_list_filter ()
{
	# Default to Bash >= 4.x
	__git_index_file_list_filter_bash
}

# Execute git ls-files, returning paths relative to the directory
# specified in the first argument, and using the options specified in
# the second argument.
__git_ls_files_helper ()
{
	(
		test -n "${CDPATH+set}" && unset CDPATH
		# NOTE: $2 is not quoted in order to support multiple options
		cd "$1" && git ls-files --exclude-standard $2
	) 2>/dev/null
}


# Execute git diff-index, returning paths relative to the directory
# specified in the first argument, and using the tree object id
# specified in the second argument.
__git_diff_index_helper ()
{
	(
		test -n "${CDPATH+set}" && unset CDPATH
		cd "$1" && git diff-index --name-only --relative "$2"
	) 2>/dev/null
}

# __git_index_files accepts 1 or 2 arguments:
# 1: Options to pass to ls-files (required).
#    Supported options are --cached, --modified, --deleted, --others,
#    and --directory.
# 2: A directory path (optional).
#    If provided, only files within the specified directory are listed.
#    Sub directories are never recursed.  Path must have a trailing
#    slash.
__git_index_files ()
{
	local dir="$(__gitdir)" root="${2-.}"

	if [ -d "$dir" ]; then
		__git_ls_files_helper "$root" "$1" | __git_index_file_list_filter |
			sort | uniq
	fi
}

# __git_diff_index_files accepts 1 or 2 arguments:
# 1) The id of a tree object.
# 2) A directory path (optional).
#    If provided, only files within the specified directory are listed.
#    Sub directories are never recursed.  Path must have a trailing
#    slash.
__git_diff_index_files ()
{
	local dir="$(__gitdir)" root="${2-.}"

	if [ -d "$dir" ]; then
		__git_diff_index_helper "$root" "$1" | __git_index_file_list_filter |
			sort | uniq
	fi
}

__git_heads ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir" ]; then
		git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
			refs/heads
		return
	fi
}

__git_tags ()
{
	local dir="$(__gitdir)"
	if [ -d "$dir" ]; then
		git --git-dir="$dir" for-each-ref --format='%(refname:short)' \
			refs/tags
		return
	fi
}

# __git_refs accepts 0, 1 (to pass to __gitdir), or 2 arguments
# presence of 2nd argument means use the guess heuristic employed
# by checkout for tracking branches
__git_refs ()
{
	local i hash dir="$(__gitdir "${1-}")" track="${2-}"
	local format refs
	if [ -d "$dir" ]; then
		case "$cur" in
		refs|refs/*)
			format="refname"
			refs="${cur%/*}"
			track=""
			;;
		*)
			for i in HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD; do
				if [ -e "$dir/$i" ]; then echo $i; fi
			done
			format="refname:short"
			refs="refs/tags refs/heads refs/remotes"
			;;
		esac
		git --git-dir="$dir" for-each-ref --format="%($format)" \
			$refs
		if [ -n "$track" ]; then
			# employ the heuristic used by git checkout
			# Try to find a remote branch that matches the completion word
			# but only output if the branch name is unique
			local ref entry
			git --git-dir="$dir" for-each-ref --shell --format="ref=%(refname:short)" \
				"refs/remotes/" | \
			while read -r entry; do
				eval "$entry"
				ref="${ref#*/}"
				if [[ "$ref" == "$cur"* ]]; then
					echo "$ref"
				fi
			done | sort | uniq -u
		fi
		return
	fi
	case "$cur" in
	refs|refs/*)
		git ls-remote "$dir" "$cur*" 2>/dev/null | \
		while read -r hash i; do
			case "$i" in
			*^{}) ;;
			*) echo "$i" ;;
			esac
		done
		;;
	*)
		git ls-remote "$dir" HEAD ORIG_HEAD 'refs/tags/*' 'refs/heads/*' 'refs/remotes/*' 2>/dev/null | \
		while read -r hash i; do
			case "$i" in
			*^{}) ;;
			refs/*) echo "${i#refs/*/}" ;;
			*) echo "$i" ;;
			esac
		done
		;;
	esac
}

# __git_refs2 requires 1 argument (to pass to __git_refs)
__git_refs2 ()
{
	local i
	for i in $(__git_refs "$1"); do
		echo "$i:$i"
	done
}

# __git_refs_remotes requires 1 argument (to pass to ls-remote)
__git_refs_remotes ()
{
	local i hash
	git ls-remote "$1" 'refs/heads/*' 2>/dev/null | \
	while read -r hash i; do
		echo "$i:refs/remotes/$1/${i#refs/heads/}"
	done
}

__git_remotes ()
{
	local i IFS=$'\n' d="$(__gitdir)"
	test -d "$d/remotes" && ls -1 "$d/remotes"
	for i in $(git --git-dir="$d" config --get-regexp 'remote\..*\.url' 2>/dev/null); do
		i="${i#remote.}"
		echo "${i/.url*/}"
	done
}

__git_list_merge_strategies ()
{
	git merge -s help 2>&1 |
	sed -n -e '/[Aa]vailable strategies are: /,/^$/{
		s/\.$//
		s/.*://
		s/^[ 	]*//
		s/[ 	]*$//
		p
	}'
}

__git_merge_strategies=
# 'git merge -s help' (and thus detection of the merge strategy
# list) fails, unfortunately, if run outside of any git working
# tree.  __git_merge_strategies is set to the empty string in
# that case, and the detection will be repeated the next time it
# is needed.
__git_compute_merge_strategies ()
{
	test -n "$__git_merge_strategies" ||
	__git_merge_strategies=$(__git_list_merge_strategies)
}

__git_complete_revlist_file ()
{
	local pfx ls ref cur_="$cur"
	case "$cur_" in
	*..?*:*)
		return
		;;
	?*:*)
		ref="${cur_%%:*}"
		cur_="${cur_#*:}"
		case "$cur_" in
		?*/*)
			pfx="${cur_%/*}"
			cur_="${cur_##*/}"
			ls="$ref:$pfx"
			pfx="$pfx/"
			;;
		*)
			ls="$ref"
			;;
		esac

		case "$COMP_WORDBREAKS" in
		*:*) : great ;;
		*)   pfx="$ref:$pfx" ;;
		esac

		__gitcomp_nl "$(git --git-dir="$(__gitdir)" ls-tree "$ls" 2>/dev/null \
				| sed '/^100... blob /{
				           s,^.*	,,
				           s,$, ,
				       }
				       /^120000 blob /{
				           s,^.*	,,
				           s,$, ,
				       }
				       /^040000 tree /{
				           s,^.*	,,
				           s,$,/,
				       }
				       s/^.*	//')" \
			"$pfx" "$cur_" ""
		;;
	*...*)
		pfx="${cur_%...*}..."
		cur_="${cur_#*...}"
		__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		;;
	*..*)
		pfx="${cur_%..*}.."
		cur_="${cur_#*..}"
		__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		;;
	*)
		__gitcomp_nl "$(__git_refs)"
		;;
	esac
}


# __git_complete_index_file requires 1 argument: the options to pass to
# ls-file
__git_complete_index_file ()
{
	local pfx cur_="$cur"

	case "$cur_" in
	?*/*)
		pfx="${cur_%/*}"
		cur_="${cur_##*/}"
		pfx="${pfx}/"

		__gitcomp_file "$(__git_index_files "$1" "$pfx")" "$pfx" "$cur_"
		;;
	*)
		__gitcomp_file "$(__git_index_files "$1")" "" "$cur_"
		;;
	esac
}

# __git_complete_diff_index_file requires 1 argument: the id of a tree
# object
__git_complete_diff_index_file ()
{
	local pfx cur_="$cur"

	case "$cur_" in
	?*/*)
		pfx="${cur_%/*}"
		cur_="${cur_##*/}"
		pfx="${pfx}/"

		__gitcomp_file "$(__git_diff_index_files "$1" "$pfx")" "$pfx" "$cur_"
		;;
	*)
		__gitcomp_file "$(__git_diff_index_files "$1")" "" "$cur_"
		;;
	esac
}

__git_complete_file ()
{
	__git_complete_revlist_file
}

__git_complete_revlist ()
{
	__git_complete_revlist_file
}

__git_complete_remote_or_refspec ()
{
	local cur_="$cur" cmd="${words[1]}"
	local i c=2 remote="" pfx="" lhs=1 no_complete_refspec=0
	if [ "$cmd" = "remote" ]; then
		((c++))
	fi
	while [ $c -lt $cword ]; do
		i="${words[c]}"
		case "$i" in
		--mirror) [ "$cmd" = "push" ] && no_complete_refspec=1 ;;
		--all)
			case "$cmd" in
			push) no_complete_refspec=1 ;;
			fetch)
				COMPREPLY=()
				return
				;;
			*) ;;
			esac
			;;
		-*) ;;
		*) remote="$i"; break ;;
		esac
		((c++))
	done
	if [ -z "$remote" ]; then
		__gitcomp_nl "$(__git_remotes)"
		return
	fi
	if [ $no_complete_refspec = 1 ]; then
		COMPREPLY=()
		return
	fi
	[ "$remote" = "." ] && remote=
	case "$cur_" in
	*:*)
		case "$COMP_WORDBREAKS" in
		*:*) : great ;;
		*)   pfx="${cur_%%:*}:" ;;
		esac
		cur_="${cur_#*:}"
		lhs=0
		;;
	+*)
		pfx="+"
		cur_="${cur_#+}"
		;;
	esac
	case "$cmd" in
	fetch)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs2 "$remote")" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		fi
		;;
	pull|remote)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		fi
		;;
	push)
		if [ $lhs = 1 ]; then
			__gitcomp_nl "$(__git_refs)" "$pfx" "$cur_"
		else
			__gitcomp_nl "$(__git_refs "$remote")" "$pfx" "$cur_"
		fi
		;;
	esac
}

__git_complete_strategy ()
{
	__git_compute_merge_strategies
	case "$prev" in
	-s|--strategy)
		__gitcomp "$__git_merge_strategies"
		return 0
	esac
	case "$cur" in
	--strategy=*)
		__gitcomp "$__git_merge_strategies" "" "${cur##--strategy=}"
		return 0
		;;
	esac
	return 1
}

__git_commands () {
	if test -n "${GIT_TESTING_COMMAND_COMPLETION:-}"
	then
		printf "%s" "${GIT_TESTING_COMMAND_COMPLETION}"
	else
		git help -a|egrep '^  [a-zA-Z0-9]'
	fi
}

__git_list_all_commands ()
{
	local i IFS=" "$'\n'
	for i in $(__git_commands)
	do
		case $i in
		*--*)             : helper pattern;;
		*) echo $i;;
		esac
	done
}

__git_all_commands=
__git_compute_all_commands ()
{
	test -n "$__git_all_commands" ||
	__git_all_commands=$(__git_list_all_commands)
}

__git_list_porcelain_commands ()
{
	local i IFS=" "$'\n'
	__git_compute_all_commands
	for i in $__git_all_commands
	do
		case $i in
		*--*)             : helper pattern;;
		applymbox)        : ask gittus;;
		applypatch)       : ask gittus;;
		archimport)       : import;;
		cat-file)         : plumbing;;
		check-attr)       : plumbing;;
		check-ignore)     : plumbing;;
		check-ref-format) : plumbing;;
		checkout-index)   : plumbing;;
		commit-tree)      : plumbing;;
		count-objects)    : infrequent;;
		credential-cache) : credentials helper;;
		credential-store) : credentials helper;;
		cvsexportcommit)  : export;;
		cvsimport)        : import;;
		cvsserver)        : daemon;;
		daemon)           : daemon;;
		diff-files)       : plumbing;;
		diff-index)       : plumbing;;
		diff-tree)        : plumbing;;
		fast-import)      : import;;
		fast-export)      : export;;
		fsck-objects)     : plumbing;;
		fetch-pack)       : plumbing;;
		fmt-merge-msg)    : plumbing;;
		for-each-ref)     : plumbing;;
		hash-object)      : plumbing;;
		http-*)           : transport;;
		index-pack)       : plumbing;;
		init-db)          : deprecated;;
		local-fetch)      : plumbing;;
		lost-found)       : infrequent;;
		ls-files)         : plumbing;;
		ls-remote)        : plumbing;;
		ls-tree)          : plumbing;;
		mailinfo)         : plumbing;;
		mailsplit)        : plumbing;;
		merge-*)          : plumbing;;
		mktree)           : plumbing;;
		mktag)            : plumbing;;
		pack-objects)     : plumbing;;
		pack-redundant)   : plumbing;;
		pack-refs)        : plumbing;;
		parse-remote)     : plumbing;;
		patch-id)         : plumbing;;
		peek-remote)      : plumbing;;
		prune)            : plumbing;;
		prune-packed)     : plumbing;;
		quiltimport)      : import;;
		read-tree)        : plumbing;;
		receive-pack)     : plumbing;;
		remote-*)         : transport;;
		repo-config)      : deprecated;;
		rerere)           : plumbing;;
		rev-list)         : plumbing;;
		rev-parse)        : plumbing;;
		runstatus)        : plumbing;;
		sh-setup)         : internal;;
		shell)            : daemon;;
		show-ref)         : plumbing;;
		send-pack)        : plumbing;;
		show-index)       : plumbing;;
		ssh-*)            : transport;;
		stripspace)       : plumbing;;
		symbolic-ref)     : plumbing;;
		tar-tree)         : deprecated;;
		unpack-file)      : plumbing;;
		unpack-objects)   : plumbing;;
		update-index)     : plumbing;;
		update-ref)       : plumbing;;
		update-server-info) : daemon;;
		upload-archive)   : plumbing;;
		upload-pack)      : plumbing;;
		write-tree)       : plumbing;;
		var)              : infrequent;;
		verify-pack)      : infrequent;;
		verify-tag)       : plumbing;;
		*) echo $i;;
		esac
	done
}

__git_porcelain_commands=
__git_compute_porcelain_commands ()
{
	__git_compute_all_commands
	test -n "$__git_porcelain_commands" ||
	__git_porcelain_commands=$(__git_list_porcelain_commands)
}

__git_pretty_aliases ()
{
	local i IFS=$'\n'
	for i in $(git --git-dir="$(__gitdir)" config --get-regexp "pretty\..*" 2>/dev/null); do
		case "$i" in
		pretty.*)
			i="${i#pretty.}"
			echo "${i/ */}"
			;;
		esac
	done
}

__git_aliases ()
{
	local i IFS=$'\n'
	for i in $(git 
