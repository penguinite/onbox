
HOST="xmoo@tilambda.zone"
DIR="~/Public/http/pothole/"

ssh $HOST "rm -rf $DIR"
hugo
# Maybe I should use rsync instead.
ssh $HOST "mkdir $DIR"
scp -r public/* "$HOST:$DIR"

# Ensuring the web server can read the directory
ssh $HOST "chmod 755 -R $DIR"
