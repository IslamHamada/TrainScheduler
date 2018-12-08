const express = require('express')
const app = express()
const port = process.env.PORT||3000
const fs = require('fs');
const path = require('path')


app.set('view engine', 'ejs');

app.use(express.static(path.join(__dirname, 'views')));

app.get('/', (req, res) =>{
  let tardiness = fs.readFileSync("tardiness.txt");
  let timelines = fs.readFileSync("timelines.txt",'utf-8');
  let array = parse(timelines);
  let ends = fs.readFileSync("ends.txt",'utf-8');
  ends = ends.substring(1,ends.length-1);
  ends = ends.split(',');
  let template = {
    tardiness: tardiness,
    timelines: array,
    ends: ends
  }
  res.render('table',template);
 })

function parse(s){
  s = s.substring(1, s.length-1);
  s = s.replace(/\[/g,'');
  s = s.substring(0, s.length-1);
  arr = s.split('],');
  for(let i=0;i<arr.length;i++){
    // let x = arr[i]
    arr[i] = arr[i].replace(/e\(/g,'')
    arr[i] = arr[i].substring(0,arr[i].length-1).split('),');
    for(let j=0;j<arr[i].length;j++){
      arr[i][j] = arr[i][j].split(",");
    }
  }
  return arr;
}

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
