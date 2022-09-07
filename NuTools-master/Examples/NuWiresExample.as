#include "NuLib.as";

void onInit(CRules@ this)
{
    Nu::IntKeyDictionary dic = Nu::IntKeyDictionary();

    dic.set(5, 4);
    dic.set(5, 5);

    dic.set(1, 1);

    dic.set(7, 7);

    dic.set(0, 0);

    dic.delete(7);

    dic.set(9, 9);

    u32 value1;
    u32 value2;
    u32 value3;
    u32 value4;

    if(!dic.get(5, value1)){print("wat1?");}
    if(!dic.get(1, value2)){print("wat2?");}
    if(!dic.get(7, value3)){print("wat3?");}
    if(!dic.get(9, value4)){print("wat4?");}

    print(value1 + " " + value2 + " " + value3 + " " + value4);
}