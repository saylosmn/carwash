const cfg = window.EASY_CONFIG || {};
const root = document.querySelector('#post-feed');
const status = document.querySelector('#posts-status');
const more = document.querySelector('#posts-more');
let offset = 0, busy = false;
async function loadPosts() {
  if (busy || !cfg.supabaseUrl || !cfg.supabaseAnonKey) return;
  busy = true; more.disabled = true;
  status.textContent = 'Нийтлэл ачаалж байна…';
  try {
    const url = new URL('/rest/v1/posts', cfg.supabaseUrl);
    url.search = new URLSearchParams({select:'id,caption,image_path,created_at',published:'eq.true',order:'created_at.desc,id.desc',limit:'6',offset:String(offset)});
    const response = await fetch(url,{headers:{apikey:cfg.supabaseAnonKey},signal:AbortSignal.timeout(15000)});
    if (!response.ok) throw new Error('load');
    const posts = await response.json();
    for (const post of posts) {
      const card = document.createElement('article'); card.className = 'post-card';
      const img = document.createElement('img'); img.loading = 'lazy'; img.alt = post.caption.slice(0,160);
      img.src = `${cfg.supabaseUrl}/storage/v1/object/public/post-images/${encodeURIComponent(post.image_path)}`;
      const time = document.createElement('time'); time.dateTime = post.created_at;
      time.textContent = new Date(post.created_at).toLocaleDateString('mn-MN',{timeZone:'Asia/Ulaanbaatar'});
      const caption = document.createElement('p'); caption.textContent = post.caption;
      card.append(img,time,caption); root.append(card);
    }
    offset += posts.length; more.hidden = posts.length < 6;
    more.textContent = 'Цааш үзэх'; status.textContent = offset ? '' : 'Бодит ажлын зураг, мэдээллээ удахгүй оруулна.';
  } catch {
    status.textContent = 'Нийтлэл ачаалсангүй. Дахин оролдоно уу.';
    more.hidden = false; more.textContent = 'Дахин ачаалах';
  } finally { busy = false; more.disabled = false; }
}
more.onclick = loadPosts;
loadPosts();
