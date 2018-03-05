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

function check_status {
	status=$(echo $1 | jq '.status')
	if [ $status != "\"success\"" ] ; then
		echo "Connection failed / Incorrect request"
		exit 1
	fi
}

function check_if_last_quote_exists {
	if [ ! -f /tmp/last_quote_id ]; then
		echo "No prev quote"
		exit 1
	fi
}

function save_id {
	id=$(echo $1 | jq '.quote.id')
	echo $id > /tmp/last_quote_id
}

function parse_quote {
	quote=$(echo $1 | jq '.quote.quote')
	echo $quote
}

if [ -z $1 ] ; then
	op="daily"
else
	op=$1
fi

if [ $op == "daily" ] ; then
	info_message="Quote for today: "
	response=$($CURL_GET $API_URL/api/daily)
	check_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "next" ] ; then 
	check_if_last_quote_exists
	info_message="Next quote: "
	prev_id=$(cat /tmp/last_quote_id)
	response=$($CURL_GET $API_URL/api/quote/$prev_id/next)
	check_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "prev" ] ; then 
	check_if_last_quote_exists
	info_message="Next quote: "
	prev_id=$(cat /tmp/last_quote_id)
	response=$($CURL_GET $API_URL/api/quote/$prev_id/prev)
	check_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "random" ] ; then 
	info_message="Random quote: "
	response=$($CURL_GET $API_URL/api/random)
	check_status "$response"
	save_id "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "all" ] ; then
	info_message="All quotes: "
	response=$($CURL_GET $API_URL/api/quotes)
	check_status "$response"
	quotes=$(echo $response | jq '.quotes[].quote')
	print_quote "$quotes" "$info_message"
elif [ $op == "get" ] && [ -n "$2" ] ; then
	info_message="Quote $2: "
	response=$($CURL_GET $API_URL/api/quote/$2)
	check_status "$response"
	print_quote "$(parse_quote "$response")" "$info_message"
elif [ $op == "submit" ] && [ -n "$2" ] ; then
	#TODO: check if works
	response=$($CURL_POST -F "Quote=$2" -F "Date="$3"" -F "Annotation="$4"" $API_URL/api/submit)
	check_status "$response"
	echo "Success!"
else
	echo -e "\e[1mHelp for wquote: \e[0m"
	echo -e "[] parameters are required () are optional\n"
	echo -e "\twqoute daily - get daily quote"
	echo -e "\twquote random - get random quote"
	echo -e "\twqoute all - get all quotes"
	echo -e "\twqoute get [id] - get quote with given ID"
	echo -e "\twquote submit [quote] (date) (annotation) - submit a quote"
fi


