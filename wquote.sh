#!/bin/bash

API_URL="https://alo-quotes.tk"
CURL_GET="curl --silent -H \"Accept: application/json\" -H \"Content-Type: application/json\" -X GET"
CURL_POST="curl -X POST"

function print_quote {
	if [ -n "$2" ] ; then
		echo -e "\e[1m$2\e[0m"
	fi
	echo "$1"
}

function check_msg_status {
	msg_status=$(echo $1 | jq '.status')
	if [ $msg_status != "\"Success\"" ] ; then
		echo "Connection failed / Incorrect request"
		exit 1
	fi
}

function check_if_prev_quote_exists {
	prev=$(cat /tmp/prev_quote_id)
	if [ -z "$prev" ] || [ "$prev" == "null" ] ; then
		echo Prev quote is null
		exit 1
	fi
}

function check_if_next_quote_exists {
	next=$(cat /tmp/next_quote_id)
	if [ -z "$next" ] || [ "$next" == "null" ] ; then
		echo Next quote is null
		exit 1
	fi
}

function save_id {
	prev_id=$(echo $1 | jq '.next')
	next_id=$(echo $1 | jq '.prev')
	echo $next_id > /tmp/next_quote_id
	echo $prev_id > /tmp/prev_quote_id
}

function parse_quote {
	quote=$(echo $1 | jq '.quote.text')
	echo $quote
}

if [ -z $1 ] ; then
	op="daily"
else
	op=$1
fi

if [ $op == "daily" ] ; then
	info_message="Quote for today: "
	response=$($CURL_GET $API_URL/api/daily/)
	check_msg_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "next" ] ; then 
	check_if_next_quote_exists
	info_message="Next quote: "
	next_id=$(cat /tmp/next_quote_id)
	response=$($CURL_GET $API_URL/api/quotes/$next_id/)
	check_msg_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "prev" ] ; then 
	check_if_prev_quote_exists
	info_message="Prev quote: "
	prev_id=$(cat /tmp/prev_quote_id)
	response=$($CURL_GET $API_URL/api/quotes/$prev_id/)
	check_msg_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "random" ] ; then 
	info_message="Random quote: "
	response=$($CURL_GET $API_URL/api/random/)
	check_msg_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "all" ] ; then
	info_message="All quotes: "
	response=$($CURL_GET $API_URL/api/quotes/)
	check_msg_status "$response"
	quotes=$(echo $response | jq '.quote[].text')
	print_quote "$quotes" "$info_message"
elif [ $op == "get" ] && [ -n "$2" ] ; then
	info_message="Quote $2: "
	response=$($CURL_GET $API_URL/api/quotes/$2/)
	check_msg_status "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
else
	echo -e "\e[1mHelp for wquote: \e[0m"
	echo -e "[] parameters are required () are optional\n"
	echo -e "\twqoute daily - get daily quote"
	echo -e "\twquote random - get random quote"
	echo -e "\twquote next - get next quote"
	echo -e "\twquote prev - get prev quote"
	echo -e "\twqoute all - get all quotes"
	echo -e "\twqoute get [id] - get quote with given ID"
	echo -e "\twquote submit [quote] (date) (annotation) - submit a quote"
fi
