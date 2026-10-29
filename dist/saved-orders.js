(()=>{
  const key='easycarwash.savedOrders.v1';
  const read=()=>{try{const rows=JSON.parse(localStorage.getItem(key)||'[]');return Array.isArray(rows)?rows.filter(x=>typeof x?.token==='string'&&/^[0-9a-f-]{36}$/i.test(x.token)):[]}catch{return []}};
  const save=(order)=>{try{const rows=[order,...read().filter(x=>x.token!==order.token)].slice(0,20);localStorage.setItem(key,JSON.stringify(rows));return true}catch{return false}};
  window.EASY_SAVED_ORDERS={read,save};
})();
