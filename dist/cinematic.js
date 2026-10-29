(()=>{
const init=()=>{
 document.body.classList.add('cinematic');
 const hero=document.querySelector('.hero'), visual=document.querySelector('.hero-image'),form=document.querySelector('#booking-form');
 visual.querySelectorAll('img').forEach(img=>img.src='studio-car.png');
 hero.append(form);form.classList.add('studio-booking');
 document.querySelector('.hero-copy h1').innerHTML='БОХИРДЛООС<br><em>ГЯЛАЛЗАХ ХҮРТЭЛ.</em>';
 document.querySelector('.hero-copy>p').textContent='Таны машин. Таны байршил. EASY CAR WASH.';
 const control=document.createElement('div');control.className='wash-control';control.innerHTML='<span>БОХИР</span><input aria-label="Угаалгын шилжилт" type="range" min="0" max="100" value="0"><span>ЦЭВЭР</span>';visual.append(control);
 const range=control.querySelector('input');let manual=false;const set=p=>{const v=Math.max(0,Math.min(1,p));visual.style.setProperty('--reveal',`${(1-v)*100}%`);visual.style.setProperty('--clean-progress',v);range.value=Math.round(v*100)};range.oninput=()=>{manual=true;set(Number(range.value)/100)};
 const three=document.createElement('script');three.src='https://cdn.jsdelivr.net/npm/three@0.150.1/build/three.min.js';three.onload=()=>{const loader=document.createElement('script');loader.src='https://cdn.jsdelivr.net/npm/three@0.150.1/examples/js/loaders/GLTFLoader.js';loader.onload=()=>{const carScript=document.createElement('script');carScript.src='model-3d.js';document.body.append(carScript)};document.body.append(loader)};document.body.append(three);
 window.addEventListener('scroll',()=>{if(!manual)set(Math.min(1,Math.max(0,window.scrollY/(window.innerHeight*.65))))},{passive:true});set(0);
};if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
