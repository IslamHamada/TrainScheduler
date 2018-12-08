format = function (x){
  h = math.floor(x/60);
  m = x-h;
  return String(x)+":"+String(m);
}

// let a = function (){
//   alert("E");
// }
// a();
// <% a();%>
// <td><%=format(x[2])%></td>
