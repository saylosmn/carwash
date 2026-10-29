(()=>{
const init=()=>{
 document.body.classList.add('cinematic');
 const hero=document.querySelector('.hero'), visual=document.querySelector('.hero-image'),form=document.querySelector('#booking-form');
 visual.querySelectorAll('img').forEach(img=>img.src='studio-car.png');
 hero.append(form);form.classList.add('studio-booking');
 document.querySelector('.hero-copy h1').innerHTML='БОХИРДЛООС<br><em>ГЯЛАЛЗАХ ХҮРТЭЛ.</em>';
 document.querySelector('.hero-copy>p').textContent='Таны машин. Таны байршил. EASY CAR WASH.';
 const control=document.createElement('div');control.className='wash-control';control.innerHTML='<span>БОХИР</span><input aria-label="Угаалгын шилжилт" type="range" min="0" max="100" value="0"><span>ЦЭВЭР</span>';visual.append(control);
 const range=control.querySelector('input');const set=p=>{visual.style.setProperty('--clean-progress',p);range.value=p*100};range.oninput=()=>set(range.value/100);
 window.addEventListener('scroll',()=>set(Math.min(1,Math.max(0,window.scrollY/(window.innerHeight*.65)))),{passive:true});set(0);
};if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
