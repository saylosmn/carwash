(()=>{
  const init=()=>{
    document.body.classList.add('cinematic');
    const hero=document.querySelector('.hero');
    const visual=document.querySelector('.hero-image');
    const form=document.querySelector('#booking-form');
    if(!hero||!visual||!form)return;
    const source=form.parentElement;
    hero.append(form);
    if(source?.classList.contains('booking-source'))source.remove();
    form.classList.add('studio-booking');

    const control=document.createElement('div');
    control.className='wash-control';
    control.innerHTML='<span>БОХИР</span><input aria-label="Бохир цэвэр зураг шилжүүлэх" type="range" min="0" max="100" value="0"><span>ЦЭВЭР</span>';
    visual.append(control);
    const range=control.querySelector('input');
    let manual=false;
    const setProgress=value=>{
      const progress=Math.max(0,Math.min(1,value));
      visual.style.setProperty('--reveal',`${Math.round(progress*100)}%`);
      range.value=String(Math.round(progress*100));
      visual.classList.toggle('fully-clean',progress>=.995);
    };
    range.addEventListener('input',()=>{manual=true;setProgress(Number(range.value)/100)});
    let frame=0;
    window.addEventListener('scroll',()=>{
      if(manual||frame)return;
      frame=requestAnimationFrame(()=>{
        frame=0;
        setProgress(Math.min(1,window.scrollY/(window.innerHeight*.75)));
      });
    },{passive:true});
    setProgress(0);

    const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{
      if(entry.isIntersecting){entry.target.classList.add('in-view');observer.unobserve(entry.target)}
    }),{threshold:.12});
    document.querySelectorAll('.service-grid article,.how article,.hero-copy h1,.studio-booking').forEach((item,index)=>{
      item.style.setProperty('--stagger',`${Math.min(index,5)*85}ms`);
      observer.observe(item);
    });
  };
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
})();
