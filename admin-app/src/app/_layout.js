import {Stack} from 'expo-router';
import {colors} from '../theme';
export default function Layout(){return <Stack screenOptions={{headerStyle:{backgroundColor:colors.bg},headerTintColor:colors.text,contentStyle:{backgroundColor:colors.bg}}}><Stack.Screen name="index" options={{title:'EASY CAR WASH'}}/><Stack.Screen name="[id]" options={{title:'Захиалгын дэлгэрэнгүй'}}/></Stack>}
