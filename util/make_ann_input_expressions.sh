#!/bin/bash

# This script generates the ANN input expressions and list used for the neural network.

ALLNAMES=""
export LISTFILE=ann_input_list.conf

function addallnames {
	if [ "A$OUTFIRST" = "ATRUE" ]; then
		echo ", " >> $LISTFILE
	fi
	export OUTFIRST="TRUE"
	echo -n "\"${1}\"" >> $LISTFILE
	
	ALLNAMES="${ALLNAMES}\"${1}\","
	ALLNAMES="${ALLNAMES} `echo -e '\n'`"
}

function word_prop {
	echo "ann_basic_${1} = \"added_${1} / added_word_count\";"
	echo "ann_prev_${1} = \"previous_${1} / previous_word_count\";"
	echo "ann_${1} = \"added_${1} / added_word_count / (previous_${1} / previous_word_count + 1.0)\";"
	echo "ann_removed_${1} = \"removed_${1} / removed_word_count / (previous_${1} / previous_word_count + 1.0)\";"
	echo "ann_added_cnt_${1} = \"added_${1} / 20 \";"
	addallnames "ann_${1}"
	addallnames "ann_removed_${1}"
	addallnames "ann_added_cnt_${1}"
	#addallnames "ann_basic_${1}"
	#addallnames "ann_prev_${1}"
}

function basic_added_word_prop {
	echo "ann_${1} = \"${1} / added_word_count\";"
	addallnames "ann_${1}"
}

function linear_scale {
	HIGH=$3
	LOW=$2
	M="`echo "scale=8;1/(${HIGH}-${LOW})" | bc`"
	B="`echo "scale=8;0-${M}*${LOW}" | bc`"
	echo "ann_${1} = \"${M} * ${1} + ${B}\";"
	addallnames "ann_${1}"
}

function diff_linear_scale {
	HIGH=$3
	LOW=$2
	M="`echo "scale=8;1/(${HIGH}-${LOW})" | bc`"
	B="`echo "scale=8;0-${M}*${LOW}" | bc`"
	echo "ann_added_${1} = \"${M} * (current_${1} - previous_${1}) + ${B}\";"
	echo "ann_removed_${1} = \"${M} * (previous_${1} - current_${1}) + ${B}\";"
	addallnames "ann_added_${1}"
	addallnames "ann_removed_${1}"
	linear_scale "previous_${1}" $LOW $HIGH
}

function log_scale {
	HIGH=$3
	LOW=$2
	J="`echo "scale=8;(0.1 * (${HIGH} - ${LOW}) - ${LOW} * 0.9) / (0.1 * (${HIGH} - ${LOW}))" | bc`"
	K="`echo "scale=8;0.9 / (0.1 * (${HIGH} - ${LOW}))" | bc`"
	echo "ann_${1}_log = \"1 - 1 / (${K} * ${1} + ${J})\";"
	addallnames "ann_${1}_log"
}

function spec_log_scale {
	HIGH=$4
	LOW=$3
	J="`echo "scale=8;(0.1 * (${HIGH} - ${LOW}) - ${LOW} * 0.9) / (0.1 * (${HIGH} - ${LOW}))" | bc`"
	K="`echo "scale=8;0.9 / (0.1 * (${HIGH} - ${LOW}))" | bc`"
	echo "${2} = \"1 - 1 / (${K} * ${1} + ${J})\";"
	addallnames "${2}"
}

function age_scale {
	spec_log_scale "(current_timestamp - ${1})" "ann_${1}" 0 31536000
}

function diff_charcount {
	echo "ann_${1}_add = \"(current_${1} - previous_${1}) / current_text_size\";"
	echo "ann_${1}_rem = \"(previous_${1} - current_${1}) / previous_text_size\";"
	echo "ann_${1}_cnt = \"(current_${1} - previous_${1}) / 10\";"
	echo "ann_${1}_prev = \"previous_${1} / previous_text_size\";"
	addallnames "ann_${1}_add"
	addallnames "ann_${1}_rem"
	addallnames "ann_${1}_cnt"
	#addallnames "ann_${1}_prev"
}

function boolean {
	echo "ann_${1} = \"${1}\";"
	addallnames "ann_${1}"
}

function exact {
	echo "ann_${1} = \"${1}\";"
	addallnames "ann_${1}"
}


(

echo '# File generated by make_ann_input_expressions.sh' > $LISTFILE
echo '# File generated by make_ann_input_expressions.sh'

word_prop all_lcase_word_count
#word_prop all_ucase_word_count
word_prop common_words
word_prop distinct_word_count
word_prop first_ucase_word_count
word_prop max_word_repeats
word_prop middle_ucase_word_count
word_prop novowels_word_count
word_prop numeric_word_count
word_prop part_numeric_word_count
# word_prop sex_words
# word_prop swear_words
word_prop acceptable_allcaps_words
word_prop lcase_i_words
word_prop improper_contractions
word_prop first_names
word_prop language_abbrev
# basic_added_word_prop added_reused_words

diff_charcount alpha_surrounded_digit_count
diff_charcount alpha_surrounded_punctuation_count
diff_charcount charcount_at
diff_charcount charcount_bracket
diff_charcount charcount_comma
diff_charcount charcount_exclamationpoint
diff_charcount charcount_period
diff_charcount charcount_qmark
diff_charcount charcount_rawcapitals
diff_charcount charcount_rawdigit
diff_charcount charcount_rawlowercase
diff_charcount charcount_space
diff_charcount charcount_wikichar
diff_charcount charcount_quote
diff_charcount charcount_apostrophe

diff_linear_scale extlink_count 0 6
diff_linear_scale html_count 0 16
diff_linear_scale punctuation_series_count 0 32
diff_linear_scale uncapitalized_sentence_count 0 16
diff_linear_scale unterminated_sentence_count 0 16
diff_linear_scale wikilink_count 0 20
diff_linear_scale wikimarkup_formatting_count 0 64
diff_linear_scale template_count 0 8
#diff_linear_scale template_argument_count 0 16
diff_linear_scale wikimarkup_listitem_count 0 10
diff_linear_scale wikimarkup_indent_count 0 10
diff_linear_scale proper_pluralities 0 16
diff_linear_scale redirect_count 0 2
diff_linear_scale disambiguation 0 2


linear_scale added_longest_char_run 0 6
linear_scale added_max_all_ucase_word_len 0 16
linear_scale added_max_word_len 0 30
linear_scale comment_size 0 100
linear_scale user_edit_count 0 300

log_scale added_word_count 0 1000
log_scale current_num_recent_edits 0 100
log_scale current_num_recent_reversions 0 40
log_scale current_word_count 0 1000
#log_scale user_distinct_pages 0 1024
log_scale user_edit_count 0 1024

age_scale current_page_made_time
age_scale user_reg_time

boolean current_minor
boolean comment_typo
boolean comment_auto
boolean comment_revert
boolean comment_common
boolean current_speedydel_count
boolean previous_speedydel_count

exact main_bayes_score
linear_scale main_bayes_nwords 0 20
exact two_bayes_score
linear_scale two_bayes_nwords 0 20
exact previous_bayes_score
linear_scale previous_bayes_nwords 0 20
#exact raw_bayes_score
#linear_scale raw_bayes_nwords 0 20

echo 'ann_bayes_range_top = "bayes_prob_range_top / 4";'
echo 'ann_bayes_range_high = "bayes_prob_range_high / added_distinct_word_count";'
echo 'ann_bayes_range_mid = "bayes_prob_range_mid / added_distinct_word_count";'
echo 'ann_bayes_range_low = "bayes_prob_range_low / added_distinct_word_count";'
#addallnames "ann_bayes_range_top"
#addallnames "ann_bayes_range_high"
#addallnames "ann_bayes_range_mid"
addallnames "ann_bayes_range_low"

echo 'ann_distinct_pages = "user_distinct_pages / user_edit_count";'
addallnames "ann_distinct_pages"
echo "ann_user_warns = \"user_warns * 2 / user_edit_count\";"
#echo 'ann_user_warns = "(user_warns * 2.5 - user_edit_count) / 5";'
addallnames "ann_user_warns"
echo "ann_added_reused_words = \"(added_reused_words - added_common_words) / (added_word_count - added_common_words)\";"
addallnames "ann_added_reused_words"
echo 'ann_prev_quote_portion = "previous_quote_text_size / previous_nomarkup_text_size";'
addallnames "ann_prev_quote_portion"
echo 'ann_added_quote_percent = "(added_word_count - added_noquote_words_size) / added_word_count";'
addallnames "ann_added_quote_percent"

echo 'ann_added_ucase_words = "(added_all_ucase_word_count - added_acceptable_allcaps_words) / added_word_count";'
echo 'ann_removed_ucase_words = "(removed_all_ucase_word_count - removed_acceptable_allcaps_words) / removed_word_count";'
echo 'ann_added_ucase_words_cnt = "(added_all_ucase_word_count - added_acceptable_allcaps_words) / 16";'
addallnames "ann_added_ucase_words"
addallnames "ann_removed_ucase_words"
addallnames "ann_added_ucase_words_cnt"

echo 'ann_added_speedydel = "current_speedydel_count - previous_speedydel_count";'
addallnames "ann_added_speedydel"

#echo 'ann_current_quote_mismatch = "current_charcount_quote % 2";'
#echo 'ann_previous_quote_mismatch = "previous_charcount_quote % 2";'
#echo 'ann_fixed_quote_mismatch = "(previous_charcount_quote % 2) - (current_charcount_quote % 2)";'
#addallnames "ann_current_quote_mismatch"
#addallnames "ann_previous_quote_mismatch"
#addallnames "ann_fixed_quote_mismatch"

echo
echo >> $LISTFILE


) >ann_input_expressions.conf
