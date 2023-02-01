import {*} with "./conv_node.jac";
import {*} with "./conv_edge.jac";


graph dialogue_system {
    has anchor dialogue_root;

    spawn {

        bienc = file.load_json(global.train_classifer_path);
        dialogue_root = spawn node::dialog;

        faqs = spawn node::faqs(imprint = [{"list_imprint": bienc['faqs'], "name": "faqs"}], name="faqs");
        soc = spawn node::response_only_template(imprint = [{"list_imprint":bienc['greetings'], "name": "greetings"}], name="greetings");
        eoc = spawn node::response_only_template(imprint = [{"list_imprint":bienc['goodbye'], "name": "goodbye"}], name="goodbye");
        
        events = spawn node::events(name="events");
        additional_memory = spawn node::response_only_template(name="additional_memory");
        
        save_memory = spawn node::response_only_template(name="save_memory");
        confirm_save_memory = spawn node::summary_template(imprint = [{"list_imprint":bienc['confirm_save_memory'], "name": "confirm_save_memory"}], name="confirm_save_memory");
        
        cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['cancel_memory'], "name": "cancel_memory"}], name="cancel_memory");
        confirm_cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['confirm_cancel_memory'], "name": "confirm_cancel_memory"}], name="confirm_cancel_memory");


        dialogue_root +[intent_transition(intent="faqs")]+>faqs;
        dialogue_root +[intent_transition(intent="greetings")]+>soc;
        dialogue_root +[intent_transition(intent="goodbye")]+>eoc;
        dialogue_root +[redirect_transition]+> events;

        events +[intent_transition(intent="faqs")]+>faqs;
        events +[redirect_transition]+>additional_memory;

        additional_memory +[intent_transition(intent="faqs")]+>faqs;
        additional_memory +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;
        additional_memory +[intent_transition(intent="cancel_memory")]+>cancel_memory;
        additional_memory +[redirect_transition]+>events;
        additional_memory +[redirect_confirm_transition]+>save_memory;

        save_memory +[intent_transition(intent="faqs")]+>faqs;
        save_memory +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;
        save_memory +[intent_transition(intent="cancel_memory")]+>cancel_memory;

        cancel_memory +[intent_transition(intent="faqs")]+>faqs;
        cancel_memory +[intent_transition(intent="confirm_cancel_memory")]+>confirm_cancel_memory;




        // faqs = spawn node::faqs(imprint = [{"list_imprint": bienc['faqs'], "name": "faqs"}], name="faqs");
        // dialogue_root +[intent_transition(intent="faqs")]+>faqs;

        // soc = spawn node::response_only_template(imprint = [{"list_imprint":bienc['greetings'], "name": "greetings"}], name="greetings");
        // dialogue_root +[intent_transition(intent="greetings")]+>soc;

        // eoc = spawn node::response_only_template(imprint = [{"list_imprint":bienc['goodbye'], "name": "goodbye"}], name="goodbye");
        // dialogue_root +[intent_transition(intent="goodbye")]+>eoc;


        // events = spawn node::events(name="events");
        // dialogue_root +[entity_transition(entities=["event"])]+> events;
        // dialogue_root +[redirect_transition]+> events;
        // events +[intent_transition(intent="faqs")]+>faqs;


        // additional_memory = spawn node::response_only_template(name="additional_memory");
        // events +[redirect_transition]+>additional_memory;
        // additional_memory +[intent_transition(intent="faqs")]+>faqs;
        
        // additional_memory +[redirect_transition]+>events;


        // save_memory = spawn node::response_only_template(name="save_memory");
        // additional_memory +[redirect_confirm_transition]+>save_memory;
        
        // confirm_save_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['confirm_save_memory'], "name": "confirm_save_memory"}], name="confirm_save_memory");
        // save_memory +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;
        // additional_memory +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;
        // save_memory +[intent_transition(intent="faqs")]+>faqs;

        // cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['cancel_memory'], "name": "cancel_memory"}], name="cancel_memory");
        // save_memory +[intent_transition(intent="cancel_memory")]+>cancel_memory;
        // cancel_memory +[intent_transition(intent="faqs")]+>faqs;
        // additional_memory +[intent_transition(intent="cancel_memory")]+>cancel_memory;

        // confirm_cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['confirm_cancel_memory'], "name": "confirm_cancel_memory"}], name="confirm_cancel_memory");
        // cancel_memory +[intent_transition(intent="confirm_cancel_memory")]+>confirm_cancel_memory;





        // birthday +[intent_transition(intent="cancel_memory")]+>cancel_memory;


        // // dialogue_root +[intent_transition(intent="yes")]+>yes;

        // // confirm_cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['yes'], "name": "yes"}], name="confirm_cancel_memory");
        // confirm_cancel_memory = spawn node::response_only_template(imprint = [{"list_imprint":bienc['confirm_cancel_memory'], "name": "confirm_cancel_memory"}], name="confirm_cancel_memory");
        // dialogue_root +[intent_transition(intent="no")]+>no;

        // memory = spawn node::summary_template(imprint = [{"list_imprint":bienc['memory'], "name": "memory"}], name="memory");
        // // dialogue_root +[intent_transition(intent="memory")]+>memory;
        // dialogue_root +[entity_transition(entities=["event"])]+>memory;

        // memory +[intent_transition(intent="faqs")]+>faqs;
        // memory +[intent_transition(intent="yes")]+>yes;
        // memory +[intent_transition(intent="no")]+>no;
        // memory +[redirect_transition]+>memory;

        // event_type = spawn node::event_type(name="event type");
        // dialogue_root +[entity_transition(entities=["event"])]+> event_type;

        // birthday = spawn node::event(name="birthday");
        // event_type +[redirect_transition(name="birthday")]+>birthday;
        // birthday +[intent_transition(intent="faqs")]+>faqs;
        // birthday +[intent_transition(intent="save_memory")]+>save_memory;
        // birthday +[intent_transition(intent="cancel_memory")]+>cancel_memory;
        // cancel_memory +[intent_transition(intent="confirm_cancel_memory")]+>confirm_cancel_memory;

        // vacation = spawn node::event(name="vacation");
        // event_type +[redirect_transition(name="vacation")]+>vacation;
        // vacation +[intent_transition(intent="faqs")]+>faqs;
        // vacation +[intent_transition(intent="save_memory")]+>save_memory;
        // vacation +[intent_transition(intent="cancel_memory")]+>cancel_memory;
        // cancel_memory +[intent_transition(intent="confirm_cancel_memory")]+>confirm_cancel_memory;


    }
}


