import 'react-native-url-polyfill/auto';
import {AppState,Platform} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {createClient} from '@supabase/supabase-js';

export const configured=Boolean(process.env.EXPO_PUBLIC_SUPABASE_URL&&process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY);
export const db=configured?createClient(process.env.EXPO_PUBLIC_SUPABASE_URL,process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,{
  auth:{...(Platform.OS!=='web'?{storage:AsyncStorage}:{}),autoRefreshToken:true,persistSession:true,detectSessionInUrl:false}
}):null;
if(db&&Platform.OS!=='web')AppState.addEventListener('change',state=>{if(state==='active')db.auth.startAutoRefresh();else db.auth.stopAutoRefresh()});
