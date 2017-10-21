#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define PLUGIN_VERSION "2.0"

enum _:Settings
{
	stgPrefix[32],
	stgAdminOnly,
	stgAdminFlag[2],
	stgHideAdmins,
	stgPlayerIp,
	stgAdminSeeFull,
	stgIPFormat[128],
	stgShowPort,
	stgHidden[32],
	stgLineBegin[128],
	stgLineEnd[128],
	stgMenuTitle[128],
	stgMenuFormat[128],
	stgMenuBack[32],
	stgMenuNext[32],
	stgMenuExit[32],
	stgChatFormat[128],
	stgNoAccess[128],
	stgNoIPs[128],
	stgTimeFormat[32]
}

new g_eSettings[Settings]
new Array:g_aRandomAddresses
new g_iTotalRandom

new bool:g_blName
new bool:g_blUserId
new bool:g_blIP
new bool:g_blAuthId
new bool:g_blNameM
new bool:g_blUserIdM
new bool:g_blIPM
new bool:g_blAuthIdM
new bool:g_blNameC
new bool:g_blUserIdC
new bool:g_blIPC
new bool:g_blAuthIdC
new bool:g_blPrefixC
new bool:g_blTimeC
new bool:g_blExclude

new g_szRealIP[33][32], g_szFakeIP[33][32], g_szAuthId[33][32]

public plugin_init()
{
	register_plugin("Ultimate IP Shower", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXIPShower", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_concmd("amx_showip", "cmdShowIP", ADMIN_ALL, "shows users' IP adresses")
	register_clcmd("say /showip", "menuIP")
	register_clcmd("say_team /showip", "menuIP")
	g_aRandomAddresses = ArrayCreate(10, 1)
	fileRead()
}

public plugin_end()
	ArrayDestroy(g_aRandomAddresses)

fileRead()
{
	new szConfigsName[256], szFilename[256], szHostname[64], szMapname[32]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/IPShower.ini", szConfigsName)
	get_user_name(0, szHostname, charsmax(szHostname))
	get_mapname(szMapname, charsmax(szMapname))
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[160], szKey[32], szValue[128]
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, ';': continue
				default:
				{
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
					
					if(equal(szKey, "CHAT_PREFIX"))
						copy(g_eSettings[stgPrefix], charsmax(g_eSettings[stgPrefix]), szValue)
					else if(equal(szKey, "ADMIN_ONLY"))
						g_eSettings[stgAdminOnly] = str_to_num(szValue)
					else if(equal(szKey, "ADMIN_FLAG"))
						copy(g_eSettings[stgAdminFlag], charsmax(g_eSettings[stgAdminFlag]), szValue)
					else if(equal(szKey, "HIDE_ADMINS"))
					{
						g_eSettings[stgHideAdmins] = str_to_num(szValue)
						g_blExclude = str_to_num(szValue) == 4 ? true : false
					}
					else if(equal(szKey, "PLAYER_IP"))
						g_eSettings[stgPlayerIp] = str_to_num(szValue)
					else if(equal(szKey, "ADMIN_SEEFULL"))
						g_eSettings[stgAdminSeeFull] = str_to_num(szValue)
					else if(equal(szKey, "IP_FORMAT"))
					{
						copy(g_eSettings[stgIPFormat], charsmax(g_eSettings[stgIPFormat]), szValue)
						g_blName = contain(szValue, "%name%") != -1 ? true : false
						g_blUserId = contain(szValue, "%userid%") != -1 ? true : false
						g_blIP = contain(szValue, "%ip%") != -1 ? true : false
						g_blAuthId = contain(szValue, "%authid%") != -1 ? true : false
					}
					else if(equal(szKey, "SHOW_PORT"))
						g_eSettings[stgShowPort] = str_to_num(szValue)
					else if(equal(szKey, "HIDDEN_TAG"))
						copy(g_eSettings[stgHidden], charsmax(g_eSettings[stgHidden]), szValue)
					else if(equal(szKey, "LINE_BEGIN"))
					{
						if(contain(szValue, "%hostname%") != -1)
							replace_all(szValue, charsmax(szValue), "%hostname%", szHostname)
							
						if(contain(szValue, "%map%") != -1)
							replace_all(szValue, charsmax(szValue), "%map%", szMapname)
							
						if(contain(szValue, "%newline%") != -1)
							replace_all(szValue, charsmax(szValue), "%newline%", "^n")
							
						copy(g_eSettings[stgLineBegin], charsmax(g_eSettings[stgLineBegin]), szValue)
					}
					else if(equal(szKey, "LINE_END"))
					{
						if(contain(szValue, "%hostname%") != -1)
							replace_all(szValue, charsmax(szValue), "%hostname%", szHostname)
							
						if(contain(szValue, "%map%") != -1)
							replace_all(szValue, charsmax(szValue), "%map%", szMapname)
						
						if(contain(szValue, "%newline%") != -1)
							replace_all(szValue, charsmax(szValue), "%newline%", "^n")
							
						copy(g_eSettings[stgLineEnd], charsmax(g_eSettings[stgLineEnd]), szValue)
					}
					else if(equal(szKey, "RANDOM_ADDRESSES"))
					{
						while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
						{
							trim(szKey); trim(szValue)
							ArrayPushString(g_aRandomAddresses, szKey)
						}
						
						g_iTotalRandom = ArraySize(g_aRandomAddresses)
					}
					else if(equal(szKey, "MENU_TITLE"))
						copy(g_eSettings[stgMenuTitle], charsmax(g_eSettings[stgMenuTitle]), szValue)
					else if(equal(szKey, "MENU_FORMAT"))
					{
						copy(g_eSettings[stgMenuFormat], charsmax(g_eSettings[stgMenuFormat]), szValue)
						g_blNameM = contain(szValue, "%name%") != -1 ? true : false
						g_blUserIdM = contain(szValue, "%userid%") != -1 ? true : false
						g_blIPM = contain(szValue, "%ip%") != -1 ? true : false
						g_blAuthIdM = contain(szValue, "%authid%") != -1 ? true : false
					}
					else if(equal(szKey, "MENU_BACKNAME"))
						copy(g_eSettings[stgMenuBack], charsmax(g_eSettings[stgMenuBack]), szValue)
					else if(equal(szKey, "MENU_NEXTNAME"))
						copy(g_eSettings[stgMenuNext], charsmax(g_eSettings[stgMenuNext]), szValue)
					else if(equal(szKey, "MENU_EXITNAME"))
						copy(g_eSettings[stgMenuExit], charsmax(g_eSettings[stgMenuExit]), szValue)
					else if(equal(szKey, "CHAT_FORMAT"))
					{
						copy(g_eSettings[stgChatFormat], charsmax(g_eSettings[stgChatFormat]), szValue)
						g_blNameC = contain(szValue, "%name%") != -1 ? true : false
						g_blUserIdC = contain(szValue, "%userid%") != -1 ? true : false
						g_blIPC = contain(szValue, "%ip%") != -1 ? true : false
						g_blAuthIdC = contain(szValue, "%authid%") != -1 ? true : false
						g_blPrefixC = contain(szValue, "%prefix%") != -1 ? true : false
						g_blTimeC = contain(szValue, "%time%") != -1 ? true : false
					}
					else if(equal(szKey, "NO_ACCESS"))
					{
						if(contain(szValue, "%flag%") != -1)
							replace_all(szValue, charsmax(szValue), "%flag%", g_eSettings[stgAdminFlag])
							
						copy(g_eSettings[stgNoAccess], charsmax(g_eSettings[stgNoAccess]), szValue)
					}
					else if(equal(szKey, "NO_IPS"))
						copy(g_eSettings[stgNoIPs], charsmax(g_eSettings[stgNoIPs]), szValue)
					else if(equal(szKey, "TIME_FORMAT"))
						copy(g_eSettings[stgTimeFormat], charsmax(g_eSettings[stgTimeFormat]), szValue)
				}
			}
		}
		
		fclose(iFilePointer)
	}
}

public client_putinserver(id)
	form_user_data(id)

public cmdShowIP(id)
{
	if(g_eSettings[stgAdminOnly] && !is_admin(id))
	{
		client_print(id, print_console, "%s %s", g_eSettings[stgPrefix], g_eSettings[stgNoAccess])
		return PLUGIN_HANDLED
	}
	
	new szMessage[192], szLine[128], szInfo[32], iPlayers[32], iPnum, iCount
	copy(szMessage, charsmax(szMessage), g_eSettings[stgIPFormat])
	copy(szLine, charsmax(szLine), g_eSettings[stgLineBegin])
	get_players(iPlayers, iPnum)
	
	if(contain(szLine, "%time%") != -1)
	{
		get_time(g_eSettings[stgTimeFormat], szInfo, charsmax(szInfo))
		replace_all(szLine, charsmax(szLine), "%time%", szInfo)
	}
		
	client_print(id, print_console, szLine)
	
	for(new i, iPlayer; i < iPnum; i++)
	{
		iPlayer = iPlayers[i]
		
		if(g_blExclude)
			if(is_admin(iPlayer))
				continue
		
		if(g_blName)
		{
			get_user_name(iPlayer, szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%name%", szInfo)
		}
		
		if(g_blUserId)
		{
			num_to_str(get_user_userid(iPlayer), szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%userid%", szInfo)
		}
		
		if(g_blIP)
			replace_all(szMessage, charsmax(szMessage), "%ip%", realip_access(id, iPlayer) ? g_szRealIP[iPlayer] : g_szFakeIP[iPlayer])
			
		if(g_blAuthId)
			replace_all(szMessage, charsmax(szMessage), "%authid%", g_szAuthId[iPlayer])
			
		client_print(id, print_console, szMessage)
		copy(szMessage, charsmax(szMessage), g_eSettings[stgIPFormat])
		iCount++
	}
	
	if(!iCount)
		client_print(id, print_console, g_eSettings[stgNoIPs])
		
	copy(szLine, charsmax(szLine), g_eSettings[stgLineEnd])
	
	if(contain(szLine, "%time%") != -1)
	{
		get_time(g_eSettings[stgTimeFormat], szInfo, charsmax(szInfo))
		replace_all(szLine, charsmax(szLine), "%time%", szInfo)
	}
	
	client_print(id, print_console, szLine)
	return PLUGIN_HANDLED
}

public menuIP(id)
{
	if(g_eSettings[stgAdminOnly] && !is_admin(id))
	{
		ColorChat(id, RED, "^3%s ^1%s", g_eSettings[stgPrefix], g_eSettings[stgNoAccess])
		return PLUGIN_HANDLED
	}
	
	new szMessage[192], szInfo[32], iPlayers[32], iPnum, iCount, iMenu = menu_create(g_eSettings[stgMenuTitle], "handlerIP")
	get_players(iPlayers, iPnum)
	copy(szMessage, charsmax(szMessage), g_eSettings[stgMenuFormat])
	
	for(new i, iPlayer, szUserId[6]; i < iPnum; i++)
	{
		iPlayer = iPlayers[i]
		num_to_str(get_user_userid(iPlayer), szUserId, charsmax(szUserId))
		
		if(g_blExclude)
			if(is_admin(iPlayer))
				continue
		
		if(g_blNameM)
		{
			get_user_name(iPlayer, szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%name%", szInfo)
		}
		
		if(g_blUserIdM)
			replace_all(szMessage, charsmax(szMessage), "%userid%", szUserId)
		
		if(g_blIPM)
			replace_all(szMessage, charsmax(szMessage), "%ip%", realip_access(id, iPlayer) ? g_szRealIP[iPlayer] : g_szFakeIP[iPlayer])
			
		if(g_blAuthIdM)
			replace_all(szMessage, charsmax(szMessage), "%authid%", g_szAuthId[iPlayer])
			
		menu_additem(iMenu, szMessage, szUserId, 0) 
		copy(szMessage, charsmax(szMessage), g_eSettings[stgMenuFormat])
		iCount++
	}
	
	if(!iCount)
	{
		ColorChat(id, RED, "^4%s ^1%s", g_eSettings[stgPrefix], g_eSettings[stgNoIPs])
		return PLUGIN_HANDLED
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, g_eSettings[stgMenuBack])
	menu_setprop(iMenu, MPROP_NEXTNAME, g_eSettings[stgMenuNext])
	menu_setprop(iMenu, MPROP_EXITNAME, g_eSettings[stgMenuExit])
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public handlerIP(id, iMenu, iItem)
{
	new szData[6], szName[64], iItemAccess, iItemCallback	
	menu_item_getinfo(iMenu, iItem, iItemAccess, szData, charsmax(szData), szName, charsmax(szName), iItemCallback)
	new iUserid = str_to_num(szData), iPlayer = find_player("k", iUserid)
	
	if(iPlayer)
	{
		new szMessage[192], szInfo[32]
		copy(szMessage, charsmax(szMessage), g_eSettings[stgChatFormat])
		
		if(g_blNameC)
		{
			get_user_name(iPlayer, szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%name%", szInfo)
		}
		
		if(g_blUserIdC)
		{
			num_to_str(get_user_userid(iPlayer), szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%userid%", szInfo)
		}
		
		if(g_blIPC)
			replace_all(szMessage, charsmax(szMessage), "%ip%", realip_access(id, iPlayer) ? g_szRealIP[iPlayer] : g_szFakeIP[iPlayer])
			
		if(g_blAuthIdC)
			replace_all(szMessage, charsmax(szMessage), "%authid%", g_szAuthId[iPlayer])
			
		if(g_blPrefixC)
			replace_all(szMessage, charsmax(szMessage), "%prefix%", g_eSettings[stgPrefix])
		
		if(g_blTimeC)
		{
			get_time(g_eSettings[stgTimeFormat], szInfo, charsmax(szInfo))
			replace_all(szMessage, charsmax(szMessage), "%time%", szInfo)
		}
		
		ColorChat(id, TEAM_COLOR, szMessage)
	}	
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

form_user_data(id)
{
	if(g_blAuthId || g_blAuthIdM || g_blAuthIdC)
		get_user_authid(id, g_szAuthId[id], charsmax(g_szAuthId[]))
		
	if(!g_blIP && !g_blIPM && !g_blIPC)
		return
		
	new szIP[32]
	get_user_ip(id, szIP, charsmax(szIP), g_eSettings[stgShowPort] ? 0 : 1)
	copy(g_szRealIP[id], charsmax(g_szRealIP[]), szIP)
	
	if(!is_admin(id))
		goto cpDefaultPlayer
	else
	{
		switch(g_eSettings[stgHideAdmins])
		{
			case 1: copy(szIP, charsmax(szIP), g_eSettings[stgHidden])
			case 2: form_hidden_ip(szIP)
			case 3:
			{
				new szRandom[10]
				ArrayGetString(g_aRandomAddresses, random(g_iTotalRandom), szRandom, charsmax(szRandom))
				formatex(szIP, charsmax(szIP), "%s.%i.%i", szRandom, random(256), random(256))
			}
		}
		
		copy(g_szFakeIP[id], charsmax(g_szFakeIP[]), szIP)
		return
	}
	
	cpDefaultPlayer:
	if(g_eSettings[stgPlayerIp])
		form_hidden_ip(szIP)
		
	copy(g_szFakeIP[id], charsmax(g_szFakeIP[]), szIP)
}

form_hidden_ip(szIP[32])
{
	for(new i, iCommas; i < strlen(szIP); i++)
	{
		switch(szIP[i])
		{
			case '.': iCommas++
			case ':': break
		}
		
		if(szIP[i] != '.')
			if(iCommas > 1)
				szIP[i] = '*'
	}
}

bool:is_admin(id)
	return get_user_flags(id) & read_flags(g_eSettings[stgAdminFlag]) ? true : false
	
bool:realip_access(id, iPlayer)
	return ((is_admin(id) && !is_admin(iPlayer)) || (id == iPlayer)) ? true : false