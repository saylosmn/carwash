export function setupPosts(db) {
  const form = document.querySelector('#post-form'), list = document.querySelector('#admin-posts');
  const message = document.querySelector('#post-message'), preview = document.querySelector('#post-preview');
  let editing = null, previewUrl = null, busy = false;
  const bucket = db.storage.from('post-images');
  const imageUrl = path => bucket.getPublicUrl(path).data.publicUrl;
  function reset() {
    editing = null; form.reset(); form.elements.image.required = true;
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = null; preview.hidden = true; preview.removeAttribute('src');
    form.querySelector('[type=submit]').textContent = 'Нийтлэх';
  }
  form.elements.image.onchange = () => {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    const file = form.elements.image.files[0];
    previewUrl = file ? URL.createObjectURL(file) : null;
    preview.hidden = !previewUrl;
    if (previewUrl) preview.src = previewUrl;
  };
  document.querySelector('#post-cancel').onclick = reset;
  async function load() {
    const {data,error} = await db.from('posts').select('*').order('created_at',{ascending:false});
    if (error) { message.textContent = 'Нийтлэл ачаалсангүй. Нийтлэлийн SQL шинэчлэл хийгдсэн эсэхийг шалгана уу.'; return; }
    list.replaceChildren();
    for (const post of data || []) {
      const card = document.createElement('article'); card.className = 'admin-post';
      const img = document.createElement('img'); img.src = imageUrl(post.image_path); img.alt = ''; img.loading = 'lazy';
      const text = document.createElement('p'); text.textContent = post.caption;
      const state = document.createElement('small'); state.textContent = post.published ? 'Нийтлэгдсэн' : 'Сайтаас нуусан';
      const edit = document.createElement('button'); edit.type = 'button'; edit.textContent = 'Засах';
      edit.onclick = () => {
        if (busy) return;
        reset(); editing = post; form.elements.caption.value = post.caption;
        form.elements.image.required = false; preview.src = imageUrl(post.image_path); preview.hidden = false;
        form.querySelector('[type=submit]').textContent = 'Хадгалах'; form.scrollIntoView({behavior:'smooth'});
      };
      const toggle = document.createElement('button'); toggle.type = 'button'; toggle.textContent = post.published ? 'Сайтаас нуух' : 'Нийтлэх';
      toggle.onclick = async () => {
        if (busy) return;
        toggle.disabled = true;
        try {
          const {error} = await db.from('posts').update({published:!post.published}).eq('id',post.id);
          if (error) throw error;
          message.textContent = post.published ? 'Нийтлэлийг сайтаас нуусан.' : 'Нийтлэл сайт дээр харагдана.';
          await load();
        } catch { message.textContent = 'Өөрчлөлт хадгалагдсангүй.'; }
        finally { toggle.disabled = false; }
      };
      card.append(img,state,text,edit,toggle); list.append(card);
    }
  }
  form.onsubmit = async event => {
    event.preventDefault(); if (busy) return;
    const caption = form.elements.caption.value.trim(), file = form.elements.image.files[0];
    const extensions = {'image/jpeg':'jpg','image/png':'png','image/webp':'webp'};
    if (!caption) { message.textContent = 'Тайлбараа оруулна уу.'; return; }
    if (file && (!extensions[file.type] || file.size > 5242880 || !file.size)) {
      message.textContent = '5 MB хүртэлх JPG, PNG, WebP зураг сонгоно уу.'; return;
    }
    if (!editing && !file) { message.textContent = 'Зургаа сонгоно уу.'; return; }
    busy = true; form.querySelector('fieldset').disabled = true; message.textContent = 'Хадгалж байна…';
    let committed = false;
    try {
      let path = editing?.image_path;
      if (file) {
        path = `${crypto.randomUUID()}.${extensions[file.type]}`;
        const {error} = await bucket.upload(path,file,{contentType:file.type,upsert:false});
        if (error) throw error;
      }
      const result = editing
        ? await db.from('posts').update({caption,image_path:path}).eq('id',editing.id).select('id').single()
        : await db.from('posts').insert({caption,image_path:path,published:true}).select('id').single();
      if (result.error) throw result.error;
      committed = true;
      // Retain replaced files: an interrupted response must never break a published image.
      reset(); message.textContent = 'Хадгалагдлаа. Үндсэн сайтыг шинэчилж хараарай.';
      await load();
    } catch {
      // Do not remove uploads after an ambiguous network failure; the insert may have committed.
      message.textContent = committed ? 'Хадгалагдсан, жагсаалтыг дахин ачаална уу.' : 'Баталгааг авч чадсангүй. Дахин нийтлэхээс өмнө жагсаалтаа шинэчилж шалгана уу.';
    } finally { busy = false; form.querySelector('fieldset').disabled = false; }
  };
  document.querySelector('#posts-refresh').onclick = () => { if (!busy) load(); };
  return {load, reset};
}
