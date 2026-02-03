# ARM PPU STRUCTURE SUMMARY.
1. Power modes of any device -
    SRL |NAME        | LOGIC STAT    | RAM STAT
    8   |ON          | ON            | ON
    9   |WARM_RST    | ON (WRESET)   | ON (WRESET)
    10  |DBG_RECOV   | ON (WRESET)   | ON (WRESET)
    1   |OFF_EMU     | ON            | ON
    3   |MEM_RET_EMU | ON            | ON
    0   |OFF         | OFF           | OFF
    5   |FULL_RET    | RET           | RET
    4   |LOGIC_RET   | RET           | OFF
    2   |MEM_RET     | OFF           | RET
    7   |FUNC_RET    | ON            | RET
    6   |MEM_OFF     | ON            | OFF

2. MEM - OFF means OFF - ON means on or off(no ret) - ret means ret or off(no on) - logic always exact.  
    1. 8-ON: ram (0-1-2)(off - on/off - on)
    2. 7-FUNC RET: SAME opmode as 8 ? - IMPL defined ram non functional
    3. 6-MEM-OFF: NO OP MODE- ram off
    above logic on always
    4. 5-FULL_RET: ram (0-1-2)(off - ret/off - ret)
    5. 4-LOGIC_RET: NO OP mode - ram off
    above logic ret always.
    6. 3-MEM_RET_EMU: NO op more ram on
    7. 2-MEM-RET: LOGIC OFF (0-1-2)(off - ret/off - ret).
    rest no opmode itself

3. PCSMPSTATE( ALL-ON |             )
    A. IN ALL ON ITs 0b1000 always
    B. other three bits mimic DEvpstate -when  all on is not there.
4. DEvpstate is PWR_POLICY - SRL_NO in binary 4 bit.
5. PPUHWSTAT [15:0] - SAME BUT IN one hot - that means 15:11 reserved always.
6. hIGEHER PSTATE HIGHER PRIORITY.
7. opmore (0-15) binary in op_policy,devpstate,pcsmpstate (7:4 - same meaning)
8. ppuhwstat[31:15] one hot
9. devpactive - opmode not shown in table.
10. OPMODE_PCSM_SPT_CFG ==0 -> PCSM[7:4] =0 PCSM transitions disabled.
11.     rest no opmode itself - PCSMPSTATE[7:4] -> highest supported opmode.(?)
        DevPSTATE 
12. mem_ret_emu has opmode.

13. Q- transition 8 -> everywhere and back to 8 only
    only 0->2 and 1->3 , 3->2 and 1-> 0 suported additionally. - no Q and P channel support no device awareness.

14. 4 10 not supportable on Q channel.
15. P- channel all of Q transitions.
    1. 4->6 and 6 ->4 only
    2. 5->7 & 7->5 additional.
    3. 0->6 & 1->6 6->0, 6->1 additional
    4. 8-> 10 & 10-8

16. DEVACTIVE POWER - disabled low -     
17. software PPU_PEMR controls enable of EMU.
18. EMU_EN ==1 -> internal OFF_EMU DEVPACTIVE goes high - MEM_RET_EMU DEVPACTIVE = MEM_RET | MEM_RET_EMU DEVPACTIVE.

19. EMU_EN ==0 -> internal DEVPACTIVE is as same as input one.
20. lower power mode entry - waits for relevant DEVACTIVE inputs -low.(not the intermiates if intermediates are higher). on/warm_rset exception.

Static Q channel 

21. on -> any except warm_reset -all DEVQACTIVE must be low. 
22. off -> emu off when emulation enable (for mem_ret as well).
23. final off / mem_ret  - only when emu off , power_policy off devqactive low.

Static P channel 

24. to lower power modes -> all relevant DEVPACTIVE inputs above "policy" must be low.
25. transition to higher -> no dependence on DEVPACTIVE.
26. relevant -> all between current and "policy" and  higher than current : static transition supported alone.

27.  DEvactive as well as policy - dynamic static is transaction to transaction.

28. enable to disable of dynamic power mode - ongoing transaction are completed. 

29. OFF or MEM_RET - dynamically go there- software maintains controll when it can go higher.

30. PPU reaches a lockable power -mode -stays there till unlocked. DEvactive or power policy asking higher nothing can change it. OFF, OFF_EMU, MEM_RET, MEM_RET_EMU. 1->0, 3->2 POSSIBLE. 

31. DEvqactive -requests -> transition -> 1 on any
32. when on - all low starts transition to programmed policy.
33. high on any transitions to on. warm_rst mode not dynamicin q channel.
34. PPU can move between power modes of equal and higher priority than programmed power mode policy. DBG_RECOv -not dynalically suported. 

35.  DevPACTIve considered is same as earlier static logic.

36. intermediate transition rule -
    a. first higher then lower than current.
    b. intermediate must be higher than current.
    c. for dynamic intermediate power modes also must support dynamic.
    d. after reaching intermediate - current power mode programmed policy DEvactive SAMPLING AGAIN - before making further changes - fully on-spot.

37. Initialisation - 
    a. OFF: MEM_RET :DBG_RECOv (0,2,10) -> por -> COMPONENT PCHANNEL logic is  reset.
    b. domain logic state lost.
    c. PPU initialise the domain -> in current mode -> before requesting transition. - to take care of may be scenerio.
    d. example - ON-> MEM_RET : reset happens -> component is must go back to  on to validate the memory. visible to the component.
    e. PCHANNEL is made into MRET.
    f. all these happen during reset- once reset released - further PCHANELL TO ON IS CARRIED OUT.

38. where logic is on -retained or por not asserted - this initialisation not required - as logic knows the state.

39. op mode transtions during power mode transitions.
    8->8
    8->0
    8->1
    8->10
    8->9
    6->0
    6->1
    0->2
    1->3

40. 0,1,9,10 no opmode context no impact.
41. PPUHWSTAT must be updated but no PCSM handshake.

42. on support multiple opmode without meaning to change the context without power mode changes - so that when power mode changes correct opmode iis there.

43. op mode during power transition -
    a. non-context -> context
    b. context -> non context - DEvpstate opmodebits 0
        pcsmpstate highest opmode.
        op_status = op_policy of currentl
    c. power mode tx without opmode  if op_status ~= op_policy at the begining of transfer. 

OPMODE rule - 
44. PPU_PWPR.OP_DYN_STATUS == 0 opmode is f(programmed op policy).
45. DEVPACTIVE doesnot matter
46. PPU_PWPR.OP_DYN_STATUS == 1 highest of (programmed op policy, DEVPACTIVE inputs).
47. ppu -> new op mode
    PPU is on BUT NO REquest to OFF EMU warm_rst dbg_recov. on-> on which always takes priority.
    entry delay timer gives chance to override off
48. ppu -> new op mode -> as well as power mode.
49. PPU.PWCR.OP_DEVACTIVEEN - mask - disabled low.
50. PPU_PWPR.OP_DYN_EN == 0 -> static op_mode - DEVPACTIVE does not participate in transition.

51. ladder_model: one hot with lower dont care - DEVPACTIVE 16 onward opmode 0 16 0 upper all 0 , opmode 1 16 is 1 upper all 0 then leftshift by 1.

52. independent - typically means one bit for each component.
    4 op mode DEVPACTIVE[19:16] Inputs.

53. POWER POLICY - PPU_PWPR - update only after any ongoing mode transition.

54. PPU_PWPR.PWR_DYN_EN , PPU_PWPR.OP_DYN_EN - wait till - reflection in status. PPU_PWSR.PWR_DYN_STATUS or PPU_PWSR.OP_DYN_STATUS

55. mode transitions - either complete or denied by PPU device interface.

56. static transition denied - policy reverts to current mode of PPU_PWSR.

57. dynamic transition enable set - during transition -reverts to initial PWSR.(?)

58. Denial Interrupt - static tx denied unmasked. Q-PPU PPU_STSR - identifies the report.

59. Policy unsupported - PPU_PWPR - not updated - interrupt happens on attempt.

60. e.g. MEM_RET - supported as static not as dynamic-  same as above when unsupported.

61. 

