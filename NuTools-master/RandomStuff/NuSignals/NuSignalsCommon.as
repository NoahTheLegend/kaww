#include "NuLib.as";

//Network that transfers signals between SignalConnectors.
class SignalNetwork
{
    SignalNetwork()
    {
        vars_init = true;
        signal_inputs = array<SignalConnector@>();
        signal_outputs = array<SignalConnector@>();
        @signals = @Nu::IntKeyDictionary();
    }
    bool vars_init = false;

    array<SignalConnector@> signal_inputs;//Signals sent to the network
    array<SignalConnector@> signal_outputs;//What the network sends to.

    Nu::IntKeyDictionary@ signals;//Each key refers to a signal. Try hashing if you want a key to be a string.

    void OfferSignals()
    {
        if(!vars_init) { Nu::Error("Init you haven't initialized the SignalNetwork class"); return; }

        for(u32 i = 0; i < signal_outputs.size(); i++)
        {
            signal_outputs[i].InputSignals(@signals);
        }
    }

    void TallySignals()
    {
        if(!vars_init) { Nu::Error("Init you haven't initialized the SignalNetwork class"); return; }
        
        signals.deleteAll();

        for(u32 i = 0; i < signal_inputs.size(); i++)//For each input
        {
            signals.ConsumeDictionary(@signal_inputs[i].output_signals, true);//Merge the signals dictionary with the signal_inputs[i] dictionary, and remove 0's.
            
            //if(!signal_inputs[i].tick_function_added)//If the tick function is not added.
            //{ 
                //signal_inputs[i].output_signals.deleteAll();//Wipe output_signals for it.
                //if(signal_inputs[i].getConstSignalCount() != 0)//If const signals exist.
                //{
                    //warning("Tick function not added for SignalConnector. Please call onTick of the SignalConnector class every tick for it to properly function.");
                //}
            //}
        }
    }
}

funcdef void SIGNALS_GOT(SignalConnector@, Nu::IntKeyDictionary@);

class SignalConnector
{
    SignalConnector()
    {
        tick_function_added = false;

        const_signals = Nu::IntKeyDictionary();
        output_signals = Nu::IntKeyDictionary();

        @signal_got_func = @SIGNALS_GOT(ProcessSignals);
    
        network_output = array<bool>(4, false);
        network_input = array<bool>(4, false);
    }

    bool tick_function_added;

    array<bool> network_output;//Starting from up, going clockwise. If a wire is added to a side that is true, it adds this object to it's output.
    array<bool> network_input;//Starting from up, going clockwise. If a wire is added to a side that is true, it adds this object to it's input.

    private SIGNALS_GOT@ signal_got_func;//Got that funk, awh, forgot, thaht, lyrics.
    void addSignalListener(SIGNALS_GOT@ value)
    {
        @signal_got_func = @value;
    }
    void InputSignals(Nu::IntKeyDictionary@ input_signals)
    {
        if(signal_got_func != @null)
        {
            signal_got_func(@this, @input_signals);
        }
    }

    Nu::IntKeyDictionary@ output_signals;//Signals this connector has processed and is constantly inputting together.

    void ProcessSignals(SignalConnector@ connector, Nu::IntKeyDictionary@ input_signals)//Please do not modify the input_signals, it is illergic to modification.
    {
        if(!tick_function_added){ warning("Tick function not added for SignalConnector. Please call onTick of the SignalConnector class every tick for it to properly function."); }
        connector.output_signals.ConsumeDictionary(input_signals, true);
    }

    void onTick()
    {
        if(!tick_function_added) { tick_function_added = true; }//Tick function has been added.

        output_signals.deleteAll();

        output_signals.ConsumeDictionary(const_signals, true);
    }
    
    
    private Nu::IntKeyDictionary@ const_signals;//Signals this connector constantly outputs

    void SetConstSignal(string _signal, s32 _value)
    {
        string signal_hash = _signal.getHash();
        SetConstSignal(signal_hash, _value);
    }
    void SetConstSignal(s32 _signal, s32 _value)
    {
        const_signals.set(_signal, _value);
    }

    bool GetConstSignal(string _signal, s32 &out _value)
    {
        string signal_hash = _signal.getHash();
        return GetConstSignal(signal_hash, _value);
    }
    bool GetConstSignal(s32 _signal, s32 &out _value)
    {
        return const_signals.get(_signal, _value);
    }

    array<s32> ConstKeys()
    {
        return const_signals.getKeys();
    }
    array<s32> ConstValuesInOrder()
    {
        return const_signals.getValuesInOrder();
    }

    u32 getConstSignalCount()
    {
        return const_signals.size();
    }
}