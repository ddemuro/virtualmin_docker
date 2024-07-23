#!/bin/bash

##############################################################
# Read dnsServ.lst											 #
#  Query for all records in domain.lst for each dnsServ.lst	 #
# Used for domain caching at ISPS							 #
##############################################################

##Server list location
readonly servList='lists/dnsServ.lst'
readonly domainQ='lists/domain.lst'
readonly outputFile='lists/dnsCheck.log'

echo "" > $outputFile

DOMIP=""
DOM=""
exitcode=0

cat $domainQ | while read dom; do
	cat $servList | while read servL; do
    DOM=`echo $DOM | tr -d " \t\n\r"`
    DOMIP=`echo $DOMIP | tr -d " \t\n\r"`
    dom=`echo $dom | tr -d " \t\n\r"`    
    digOutput=`echo $digOutput | tr -d " \t\n\r"`
    
    digOutput=`dig @$servL +noall +answer +time=5 $dom | awk '{ print $5 }' | tr -d " \t\n\r"`
    
    if [ "$DOM" != "" ]; then
        if [ "$DOM" == "$dom" ]; then
          if [ "$DOMIP" != "" ]; then
              if [ "$DOMIP" != "$digOutput" ]; then
                  text="ERROR: Domain: $DOM and IP: $DOMIP on $srvL don't match."
                  echo $text
                  echo $text >> $outputFile
                  echo $text | mail -s "Error on domain sync." "mail@derekdemuro.com"
                  exitcode=1
              fi
          fi
        fi
    fi

    if [ "$digOutput" == "no" ]; then
        echo "ERROR: Server $servL doesn't seem to be responding..."
        echo "ERROR: Server $servL doesn't seem to be responding..." >> $outputFile
        exitcode=1
    else
    		echo "SUCCESS: Domain $dom on server $servL has the IP: $digOutput"
    		echo "SUCCESS: Domain $dom on server $servL has the IP: $digOutput" >> $outputFile
        DOMIP=$digOutput
        DOM=$dom
    fi

	done
done

exit $exitcode