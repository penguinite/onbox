var cmdseq = @[".Name",".Test",".Summary"]

var i = -1; # For best results.
for x in cmdseq:
  inc(i)
  echo(i)
  echo(x)
  echo(cmdseq[i])
