#!/bin/bash
echo 'Installing nvm (Node.js Version Manager)...'
npm config delete prefix
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash > /dev/null 2>&1
. ~/.nvm/nvm.sh

echo 'Installing Node.js 7.9.0...'
nvm install 7.9.0 1>/dev/null
npm install --progress false --loglevel error 1>/dev/null

echo 'Retrieving Cloud Functions authorization key...'

# Retrieve the Cloud Functions authorization key
CF_ACCESS_TOKEN=`cat ~/.cf/config.json | jq -r .AccessToken | awk '{print $2}'`

export CLOUDFUNCTIONS_API_HOST=openwhisk.ng.bluemix.net

CLOUDFUNCTIONS_KEYS=`curl -XPOST -k -d "{ \"accessToken\" : \"$CF_ACCESS_TOKEN\", \"refreshToken\" : \"$CF_ACCESS_TOKEN\" }" \
  -H 'Content-Type:application/json' https://$CLOUDFUNCTIONS_API_HOST/bluemix/v2/authenticate`

echo "KMHA: CLOUDFUNCTIONS_KEYS..${CLOUDFUNCTIONS_KEYS}"
echo "KMHA: CF_ORG..${CF_ORG}"
echo "KMHA: CF_SPACE..${CF_SPACE}"
CF_UNION="$CF_ORG"_"$CF_SPACE"
echo "KMHA: CF_UNION..${CF_UNION}"
SPACE_KEY=`echo $CLOUDFUNCTIONS_KEYS | jq -r '.namespaces[] | select(.name == "'$CF_ORG'_'$CF_SPACE'") | .key'`
echo "KMHA: SPACE_KEY..${SPACE_KEY}"

SPACE_UUID=`echo $CLOUDFUNCTIONS_KEYS | jq -r '.namespaces[] | select(.name == "'$CF_ORG'_'$CF_SPACE'") | .uuid'`
echo "KMHA: SPACE_UUID..${SPACE_UUID}"

CLOUDFUNCTIONS_AUTH=$SPACE_UUID:$SPACE_KEY
echo 'KMHA:' ${CLOUDFUNCTIONS_AUTH}

echo 'KMHA: Until Configure the Cloud Functions CLI...'
# Configure the Cloud Functions CLI
wsk property set --apihost $CLOUDFUNCTIONS_API_HOST --auth "${CLOUDFUNCTIONS_AUTH}"

echo 'KMHA: Until setup.sh...'
./setup.sh -s
