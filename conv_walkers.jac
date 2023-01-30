// spawn faq_state 
walker ingest_faq {
    has kb_file;

    root: take -[dialog]-> node::dialog;
    dialog: take -[intent_transition]-> node::faqs;
    faqs {
        kb = file.load_json(global.train_faq_answer_path);
        for faq in kb {
            answer = faq["answer"];
            spawn here +[faq]+> node::faq(name = "faq", answer=answer);

        }
    }
}

// update user node
walker maintainer {
    has prev_state;
    has dialogue_context;
    root: take -[user]-> node::user;
}

// create nodes and edges
walker create_node_and_edge{
    has first_node = "";
    has second_node = "";
    has template = "";          // response_only
    has intent = "";            // greetings
    has entities = [];          // number
    has name = "";              // number


    with entry {
        if(first_node == ""): first_node = global.dialogue_root;
        bienc = file.load_json(global.train_classifer_path);


        
        if(second_node ==""){
            // std.out("first_node");
            // std.out(first_node);
            uuid_1 = spawn *(first_node) walker::get_jac_uuid;
            std.out("First");

            if(template == "response_only"){
                uuid_2 = spawn node::response_only_template(imprint=[{"list_imprint": bienc[intent], "name": intent}], name=intent);
            }
            elif(template == "extract_info"){
                if (intent in bienc){
                    uuid_2 = spawn node::extract_info_template(imprint=[{"list_imprint": bienc[intent], "name": intent}], name=intent);
                }
                else{
                    uuid_2 = spawn node::extract_info_template(name=intent);
                    global.entity_label.list::append(intent);
                }
            }
            elif(template == "collect_info"){
                if (intent in bienc){
                    uuid_2 = spawn node::collect_info_template(imprint=[{"list_imprint": bienc[intent], "name": intent}], name=intent);
                }
                else{
                    uuid_2 = spawn node::collect_info_template(name=intent);
                    global.entity_label.list::append(intent);
                }
            }

            if(intent != ""){
                uuid_1 +[intent_transition(intent=intent.str)]+> uuid_2;
            }
            elif(entities.length > 0){
                uuid_1 +[entity_transition(entities=entities)]+>uuid_2;
            }
            elif(name != ""){
                uuid_1 +[redirect_transition(name=name)]+>uuid_2;
            }

            report:custom = {"uuid_1":uuid_1.info['jid'], "uuid_2":uuid_2.info['jid']};
        }
        elif (second_node !=""){
            uuid_1 = spawn *(first_node) walker::get_jac_uuid;
            uuid_2 = spawn *(second_node) walker::get_jac_uuid;
            std.out("Second");

            if(intent != ""){
                uuid_1 +[intent_transition(intent=intent.str)]+> uuid_2;
            }
            elif(entities.length > 0){
                uuid_1 +[entity_transition(entities=entities)]+>uuid_2;
            }
            elif(name != ""){
                uuid_1 +[redirect_transition(name=name)]+>uuid_2;
            }
            report:custom = {"uuid_1":uuid_1.info['jid'], "uuid_2":uuid_2.info['jid']};
        }
    }
}

// get jac uuid work with walker create_node_and_edge
walker get_jac_uuid{
    has anchor uuid;
    with entry{
        uuid = here;
        // report:custom = uuid;
    }
}

// talker 
walker talk {
    has question, phone_number;
    has predicted_intent;
    has extracted_entities={};
    has dialogue_context ={};

    has response;
    has next_state;
    has prev_state;
    has cont_state;
    has respond = true;
    has threshold = false;

    root: take -[user]-> node::user;
    user {
        if(cont_state == ""): std.out('WALKER TALKER ERROR: cont_state is an EMPTY STR');
        take *(cont_state);
    }
    dialogue_state {
        if (respond) {
            take next_state else {
                report {
                    "name": here.name,
                    "response": "Sorry I can't handle that just yet."
                };
            }
            respond = false;
        } 
    }
}


walker test_get_embedding{
    can zs_classifier.get_embeddings;
    report zs_classifier.get_embeddings(text="yesterday was my birthday", classes=["emotion", "people", "date", "location", "age", "subject"] );
}


walker predict_zs{
        can zs_classifier.classify;
        // report zs_classifier.classify(text="yesterday was my birthday", classes=["emotion", "people", "date", "location", "age", "subject"] );
        report zs_classifier.classify(text="yesterday was my birthday", classes=["emotion", "people", "location", "age", "subject"] );
    }

// walker run predict_zs
// walker run test_get_embedding

