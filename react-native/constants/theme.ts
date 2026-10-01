import{useColorScheme}from"react-native";import{usePreferences}from"../contexts/PreferencesContext";import{colors}from"./colors";
export function useTheme(){const system=useColorScheme()==="dark";const{preferences}=usePreferences();if(preferences.theme==="dark"||(preferences.theme==="system"&&system))return colors.dark;if(preferences.theme==="sepia")return colors.sepia;return colors.light}
