
node response_only_template:dialogue_state{
    has name;

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        state_json = file.load_json(global.train_state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    arry = flow.select_response({}, state['responses'], {});
                    // arry = flow.select_response(null, state['responses'], null);
                    // std.out(arry);
                    visitor.response = arry['response'];
                    // visitor.response = arry[1];
                }
            }
        }
    }

    // can process with talk entry{
    //     visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
    // }
}
// respond only 
// redirect to dialogue_root

node extract_info_template:dialogue_state{
    has name;

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        state_json = file.load_json(global.train_state_path);
        for state in state_json{
            if (here.name == state["name"].str){
                arry = flow.select_response(state["extracted_item"], state["responses"], visitor.dialogue_context); # select a response
                if(arry["name"] != ""){
                    visitor.response = arry['response'];
                    visitor.next_state = here;
                }
                elif(arry['name'] == ""){
                    my_dict = flow.info_json(state['resource'], visitor.dialogue_context, state['variable'] ); # setup data for response

                    if(my_dict['info_json'].length != 0){
                        visitor.extracted_entities = my_dict['info_json'][0];
                        ::business_logic;
                    }
                    else{
                        ans = flow.gen_response(arry['response'], my_dict, null);
                        visitor.response = ans;
                    }
                }
            }
        }
    }
}
// confirm entity
// if entity found: redirect to collect_info_template
// faq intent_transition

node collect_info_template:dialogue_state{
    has name;

    can nlu with talk entry{
        ::extract_entities;
        ::business_logic;
        
        state_json = file.load_json(global.train_state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    if (state["variable"][0] not in visitor.dialogue_context){
                        visitor.next_state = -[redirect_transition]->[0];
                        visitor.respond = true;
                        visitor.predicted_intent = '';
                    }
                    else{
                        arry = flow.select_response({}, state['responses'], {});
                        ans = flow.gen_response(arry['response'], visitor.dialogue_context, null);
                        visitor.response = ans;
                        visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
                    }
                }
            }
        }
    }
}
// if entity not found: redirect to extract_info_template



node dialogue_state{
    has imprint;

    // hold threshold list
    // ai kit 
    can bi_enc.infer;
    can tfm_ner.extract_entity;
    can use.text_classify;

    // custom modules
    can flow.info_json;
    can flow.select_response;
    can flow.gen_response;
    can flow.collect_info;
    can flow.select_options;
    can twilio.twilio_bot;
    can flow.check_required_entity;

    can classify_intent {
        if(visitor.respond){

            imprints = -[intent_transition]->.imprint;
            intent_labels = -[intent_transition]->.edge.intent;
            std.out("intent_labels");
            std.out(intent_labels);
            max_score = global.conv_score;
            intent = "";

            for imprint in imprints {
                // std.out("imprint dict");
                // std.out(imprint[0]);
                // std.out(imprint[0]['list_imprint']);
                if (imprint[0].type == dict ){

                    best_answer = use.text_classify(
                        text = visitor.question,
                        classes = imprint[0]['list_imprint'].list
                    );
                    // std.out("best_answer");
                    // std.out(best_answer);
                    nn = best_answer['match_idx'];
                    if (best_answer['scores'][nn] > max_score){
                        max_score = best_answer['scores'][nn];
                        intent = imprint[0].name;
                    }
                    // std.out('here.name\n');
                    // std.out(here.name);
                    // std.out(best_answer['scores'][nn]);
                    // std.out(imprint[0].name);
                }
            }
            
            if (max_score > global.conv_score and intent in intent_labels){
                visitor.threshold = true;
                visitor.predicted_intent = intent;
            }
            std.log("THRESHOLD: ", global.conv_score,"   SCORE: " , max_score);
            std.log("INTENT:  ", visitor.predicted_intent);
            // std.out("intent");
        }
    }

    can extract_entities {
        if(visitor.respond){
            res = tfm_ner.extract_entity(visitor.question);
            if(res.type == list || res.type == dict){

                for ent in res {
                    ent_type = ent["entity_value"];
                    ent_text = ent["entity_text"];
                    if ( !(ent_type in visitor.extracted_entities) ){
                        visitor.extracted_entities[ent_type] = [];
                    }
                    
                    if( ent_text not in visitor.extracted_entities[ent_type] ){
                        visitor.extracted_entities[ent_type].l::append(ent_text);
                    }
                }
            }
            std.log("ENTITIES:  ", visitor.extracted_entities);
        }
    }

    can business_logic {
        visitor.dialogue_context.dict::update(visitor.extracted_entities);
        // std.out("global.entity_label");
        // std.out(global.entity_label);
        for label in global.entity_label {
            if (label in visitor.extracted_entities) {
                visitor.dialogue_context[label]=visitor.extracted_entities[label][0];
            }
        }
    }

    can nlu with talk entry {}

    can process with talk entry {
        if(visitor.respond){

            required_entities = -[entity_transition]->.edge.entities;
            redirect = -[redirect_transition]->;
            // std.out("redirect 1");
            // std.out(redirect);
            // std.out("visitor.respond");
            // std.out(visitor.respond);

            if(visitor.extracted_entities and !visitor.next_state){
                if(required_entities){
                    for entity in required_entities{
                        required = flow.check_required_entity(entity, visitor.extracted_entities.d::keys);
                        if(required == true){
                            // std.out("entity ext if");
                            // visitor.respond = true;
                            visitor.next_state = -[entity_transition(entities == entity)]->[0];
                        }
                        elif(visitor.predicted_intent){
                            // std.out("entity predict else");
                            visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
                        }
                        elif(redirect){
                            // std.out("entity redirect else");
                            // visitor.respond = true;
                            visitor.next_state = -[redirect_transition]->[0];
                        }
                        else{
                            // std.out('NOTE: Can Process else ran 2!');
                        }
                    }
                }
                elif(visitor.predicted_intent){
                    // std.out("no entity predict else");
                    visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
                }
                elif(redirect){
                    // std.out("no entity ext else");
                    // visitor.respond = true;
                    visitor.next_state = -[redirect_transition]->[0];
                }
                else{
                    // std.out('NOTE: Can Process else ran 3!');
                }
            }
            elif(visitor.predicted_intent and visitor.threshold ){
                // std.out("predict");
            // elif(visitor.predicted_intent and visitor.threshold and !visitor.next_state){
                // std.out(intent[0]['name']);
                // visitor.next_state = -[intent_transition(intent[0]['name'] == visitor.predicted_intent)]->[0];
                // visitor.respond = true;
                visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
            }
            elif(redirect and !visitor.next_state){
            // elif(redirect){
                // std.out("redirect");
                // visitor.respond = true;
                visitor.next_state = -[redirect_transition]->[0];
            }
            else{
                // std.out('NOTE: Can Process else ran 1!');
            //     visitor.next_state = null;
            }
        }
    }

    can nlg with talk entry {
        if (!visitor.respond) {
        // if (!visitor.respond and here.name != "dialogue_root") {
            report {
                "question": visitor.question,
                "name": here.name,
                "response": visitor.response
            };
            // twilio.twilio_bot(visitor.response, visitor.phone_number);
        }
    }

    can cleanup with talk entry {
        intent_labels = -[intent_transition]->.edge.intent;
        // redirect_labels = -[redirect_transition]->.edge.name;

        // if(intent_labels.length == 0 or redirect_labels.length == 0){
        if(intent_labels.length == 0){
            // std.out('set to dialogue_root prev_state');
            visitor.prev_state = global.dialogue_root;
        }
        else{
            // std.out('set to info_jid prev_state');
            visitor.prev_state = here.info['jid'];
        }
        // std.out("visitor.prev_state\n\n");
        // std.out(visitor.prev_state);
        // std.out(here.name);

        spawn *(global.main_root) walker::maintainer( 
            prev_state = visitor.prev_state,
            // skip_state = visitor.skip_state,
            dialogue_context = visitor.dialogue_context
        );
    }
}

node dialog:dialogue_state{
    has name="dialogue_root";

    can nlu with talk entry{
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        visitor.response = "this is the dialogue root";
    }

    // can process with talk entry{
    //     if
    // }
    // can nlg with talk entry{
    //     if (!visitor.respond) {
    //     // if (!visitor.respond and here.name != "dialogue_root") {
    //         report {
    //             "question": visitor.question,
    //             "name": here.name,
    //             "response": visitor.response
    //         };
    //         // twilio.twilio_bot(visitor.response, visitor.phone_number);
    //     }
    // }


}

node faqs:dialogue_state{
    has name;
    has classifier;

    can use.qa_classify;

    can nlu with talk entry{
        answers = -[faq]->.answer;
        best_answer = use.qa_classify(
            text = visitor.question,
            classes = answers
        );
        max_score = global.faq_score;
        nn = best_answer['match_idx'];
        std.log( "FAQ: " + " MATCH: ",best_answer['match'],"   SCORE: " ,best_answer['scores'][nn]);

        if (best_answer['scores'][nn] > max_score){
            visitor.response = best_answer['match'];
        }
    }

    can process with talk entry{
        if(visitor.prev_state){
            // std.out('fr process if 1');
            visitor.next_state = *(visitor.prev_state);
            // std.out("check with previous state visitor.next_state\n");
            // std.out(visitor.next_state);
            // visitor.next_state= -[intent_transition(intent==visitor.prev_state)]->;
        }
        else{ 
            // std.out('fr process if 2');
            visitor.next_state = global.dialogue_root;
        }
    }
    can cleanup with talk entry{

    }

}

node faq{
    has name;
    has answer;
}

node user {
    has id;
    has prev_state = null;
    // has skip_state = null;
    has dialogue_context ={};

    can start_conv with talk entry {
        if (here.prev_state == null) {
            here.prev_state = global.dialogue_root;
        }
        visitor.cont_state = here.prev_state;
        visitor.dialogue_context = here.dialogue_context;
        // visitor.skip_state = here.skip_state;
    }

    can update_with_conv with maintainer entry {
        here.prev_state = visitor.prev_state;
        // here.skip_state = visitor.skip_state;
        here.dialogue_context = visitor.dialogue_context;
    }
}





node event_type:dialogue_state{
    has name;
    has zs_event;

    can nlu with talk entry{
        if ("event" in  visitor.extracted_entities){
            zs_result =  zs_classifier.classify(text=visitor.question, classes=["vacation","birthday","anniversary","funeral","sport"]);
            here.zs_event = zs_result[0][visitor.question][0]['value'];
        }
        // std.out(here.zs_event);

        event_list = -->.name;
        // std.out("event_list");
        // std.out(event_list);
        edg =  -[redirect_transition]->.edge.name;
        // std.out("edg");
        // std.out(edg);
        if(here.zs_event in event_list){
            visitor.next_state = -[redirect_transition(name==here.zs_event)]->[0];
            // visitor.predicted_intent = here.zs_event;
            visitor.respond = true;
        }

    }
}

node event:dialogue_state{
    has name;
    has sentiment;
    has extracted_sentences= [];
    has first_entry = true;

    can flow.fix_sentence;
    can use.qa_classify;
    can zs_classifier.classify;
    can flow.gen_response;

    can nlu with talk entry{
        // std.out("visitor.respond");
        // std.out(visitor.respond);
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        state_json = file.load_json(global.train_state_path);
        for state in state_json{
            if (here.name == state["name"].str){

                // store quewtion []
                // check question for entity response 
                // then move on if 0 ;;;;;leave done ,fix for loop
                // 

                /// entity_clasifier
                max_score = global.entity_response_score;
                entity_response = "";
                rr = "";

                for item in state['extracted_item']{

                    if(item not in visitor.dialogue_context){
                        best_answer = use.qa_classify(
                            text = visitor.question,
                            classes = state['extracted_item'][item.str]
                        );
                        nn = best_answer['match_idx'];

                        
                        if (best_answer['scores'][nn] > max_score){
                            max_score = best_answer['scores'][nn];
                            entity_response = item;
                            // std.out("\n");
                            // std.out(best_answer);
                        }
                        rr = rand.choice(state['extracted_item'][entity_response]);
                    }
                    // dial_cont =="" do something
                    elif(entity_response==""){
                        // std.out("no best_answer");
                        rr = rand.choice(state['responses']);
                    }
                }
                /// entity_clasifier




                // arry = flow.select_response(state["extracted_item"], state["responses"], visitor.dialogue_context); # select a response
                // std.out("arry");
                // std.out(arry);
                // std.out(visitor.respond);
                // if(visitor.extracted_entities and !visitor.respond and !visitor.predicted_intent){
                if(visitor.extracted_entities and !visitor.predicted_intent){
                    here.extracted_sentences.list::append(visitor.question);
                    // std.out("store sentence");
                }

                // std.out("entity_response");
                // std.out(entity_response);
                // if(arry["name"] != ""){
                if(entity_response != ""){
                    // create_response = flow.gen_response(arry['response'].str, visitor.dialogue_context.dict);
                    // std.out(rr);
                    create_response = flow.gen_response(rr.str, visitor.dialogue_context.dict);
                    visitor.response = create_response;
                    // visitor.response = arry['response'];
                    visitor.next_state = here;
                    

                    if(!visitor.extracted_entities and !visitor.predicted_intent ): visitor.dialogue_context[entity_response] = ""; // add to dialcontext so it would ask for it again
                    
                    if (here.first_entry){
                        // std.out("here.first_entry");
                        ::classify_emotion;
                        // std.out(here.sentiment);
                        here.first_entry = false;
                        first_response = here.sentiment.str+ " " + create_response;
                        // first_response = here.sentiment.str+ " " + arry['response'].str;
                        visitor.response = first_response;

                    }
                    // visitor.respond = false;
                    
                }
                // elif(arry['name'] == ""){
                elif(entity_response == ""){
                    visitor.next_state = here;
                    // std.out("elif ran");

                    sentence = ' '.str::join(here.extracted_sentences);
                    tt = t5_sum.classify_text(
                        text = sentence,
                        min_length = 30,
                        max_length = 500
                    );
                    new_response = flow.fix_sentence(tt);
                    // std.out(here.extracted_sentences);
                    // std.out("new_response");
                    // std.out(new_response);
                    visitor.dialogue_context["summary"] = new_response;
                    // create_response = flow.gen_response(arry['response'].str, visitor.dialogue_context.dict);
                    create_response = flow.gen_response(rr.str, visitor.dialogue_context.dict);
                    visitor.response = create_response;
                }
            }
        }
    }

    can classify_emotion{
        emotion_list = file.load_json(global.sentiment_descriptors_path);
        max_score = global.emotion_score;
        emotion = "";
        
        for emotions in emotion_list{
            best_answer = use.qa_classify(
                text = visitor.question,
                classes = emotion_list[emotions.str]
            );
            nn = best_answer['match_idx'];
            
            if (best_answer['scores'][nn] > max_score){
                max_score = best_answer['scores'][nn];
                emotion = emotions;
            }
        }
        std.log( "EMOTION: " + " MATCH: ", emotion,"   SCORE: " ,max_score);

        if(emotion){
            sentiments = file.load_json(global.sentiments_path);
            here.sentiment = rand.choice(sentiments[emotion]);
        }
        
    }
}


node summary_template:dialogue_state{
    has name;

    can local.paraphraser;
    can flow.fix_sentence;
    can cl_summer.summarize;



    can summarize{ 
        sentence = ' '.str::join(visitor.dialogue_context["extracted_sentences"]);
        std.out("sentence");
        std.out(sentence);
        // tt = cl_summer.summarize(
        //     text = sentence,
        //     url = "none",
        //     sent_count = 5,
        //     summarizer_type = "LsaSummarizer"
        // );

        // tt = t5_sum.classify_text(
        //     text = sentence,
        //     min_length = 30,
        //     max_length = 500
        // );
        // std.out(tt);
        // new_response = flow.fix_sentence(tt[0]);

        tt2 = local.paraphraser(sentence);
        new_response2 = flow.fix_sentence(tt2[0]);

        // std.out("new_response 1");
        // std.out(new_response);
        // std.out("new_response 2");
        // std.out(new_response2);
        // visitor.dialogue_context["summary"] = new_response;
        visitor.dialogue_context["summary"] = new_response2;
    }

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;
        ::summarize;
            // std.out("\nSummary");
        

        state_json = file.load_json(global.train_state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    arry = flow.select_response({}, state['responses'], {});
                    // arry = flow.select_response(null, state['responses'], null);
                    // std.out(arry);
                    visitor.response = arry['response'];
                    std.out(visitor.dialogue_context['summary']);
                    // visitor.response = arry[1];
                }
            }
        }
    }

    // can process with talk entry{
    //     visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
    // }
}


node events:dialogue_state{
    has name; // event;
    has answer_list = [];
    has que = {};
    has ent_list = [];
    has required_que = [];  // fix this :: main_que, answered_que, unanswered_que // add enitiy at index 0 => main_que
    has response_entity = file.load_json("que.json");
    has event_type = file.load_json("utils/data/summary/events.json");
    has extracted_sentences = [];
    has removed_que = [];
    has first_response = true;
    has unanswer_que = [];

    // can t5_sum.classify_text;


    // can use.qa_classify;


    

    can update_que{
        // for item in visitor.extracted_entities{
        //     if (item in que.dict::keys){
        //         for ent in visitor.extracted_entities[item] {
        //             if (ent not in que[item]){
        //                 que[item].list::append(visitor.extracted_entities[item][0]);
        //             }
        //         }
        //     }
        //     else{
        //         que[item]= visitor.extracted_entities[item];
        //     }
        // }

        // if(visitor.extracted_entities and !visitor.respond){
        //     here.extracted_sentences.list::append(visitor.question);
        // }


        zs_event="";
        zs_sentiments = {};
        zs_sentiment = "";
        zs_result =  zs_classifier.classify(text=visitor.question, classes=["vacation","birthday","anniversary","funeral","sport"]);

        if(visitor.question in zs_result[0]){
            for event in zs_result[0][visitor.question]{
                if event['value'] in event_type{
                    for que in event_type[event['value']]{
                        if (que not in required_que){
                            required_que.list::append(que);
                        }
                    }
                }
            }
        }


        

        if(visitor.extracted_entities and !visitor.predicted_intent){
            here.extracted_sentences.list::append(visitor.question);
            if(first_response){
                visitor.dialogue_context["extracted_sentences"]=[visitor.question];
                first_response = false;
            }
            elif(visitor.question not in visitor.dialogue_context["extracted_sentences"]){
                visitor.dialogue_context["extracted_sentences"].list::append(visitor.question);
            }
            // std.out("store sentence");
        }

        for item in visitor.dialogue_context{
            if ( item in response_entity['response'].dict::keys ){  
            // if ( item in response_entity['response'].dict::keys and item in visitor.dialogue_context.dict::keys){  
                if (item not in ent_list and item in required_que){ 
                // if (item not in ent_list){ 
                    ent_list.list::append(item);
                    if(item not in removed_que){
                        // std.out("item was added in update");
                        removed_que.list::append(item);
                    }
                }
            }
        }


        // if('event' in visitor.dialogue_context){
        //     for event in event_type{
        //         if (event in visitor.dialogue_context['event']){
        //             for que in event_type[event]{
        //                 if (que not in tll){
        //                     tll.list::append(que);
        //                 }
        //                 // ent_list.list::append(que);
        //             }
        //         }
        //     }
        // }
        // std.out("tllmmmmmmm");
        // std.out(tll);
    }

    can nlu with talk entry{
        ::classify_intent;
        ::extract_entities;
        ::business_logic;
        
        

        ::update_que;

        if(!visitor.respond){ 
            answer_list.list::append(visitor.question);
            // std.out(que);
            
        }

        max_score = 0.01;
        entity_response = "";
        rr = "";
        remove_item = "";
        removed_que_entity="";

        




        for entity in response_entity['response'].dict::keys{
            // std.out("Tesssss");
            // std.out(ent_list);
            // std.out(unanswer_que);
            // if (entity in ent_list): std.out(entity);
            if (entity in ent_list and entity in unanswer_que): unanswer_que.list::remove(entity);
            if (entity not in removed_que and entity in required_que){
                // std.out('if entity ran');
                // if (entity not in ent_list){
                // std.out(entity);
                if (entity not in unanswer_que): unanswer_que.list::append(entity);
                for ent in response_entity['response'][entity].dict::keys{
                    if (ent in ent_list){
                        ii = 0;
                        while (max_score < 0.1){
                            
                            best_answer = use.qa_classify(
                                text = answer_list[ii],
                                classes = response_entity['response'][entity][ent]
                            );
                            nn = best_answer['match_idx'];

                            
                            if (best_answer['scores'][nn] > max_score){
                                max_score = best_answer['scores'][nn];
                                entity_response = response_entity['response'][entity][ent];
                                removed_que_entity = entity;
                            }

                            leng = answer_list.length - 1;
                            if (max_score < 0.1){
                                ii +=1;
                                if(ii >= leng){
                                    break;
                                }
                            }
                        }
                        rr = rand.choice(entity_response);

                    }
                }
                
            }
            elif( entity in required_que and entity in removed_que and entity not in ent_list and entity in visitor.extracted_entities ){
            // elif(entity in removed_que and entity not in ent_list and entity in visitor.extracted_entities ){
                // elif(entity in removed_que and entity in visitor.extracted_entities and entity not in visitor.dialogue_context ){
                // std.out('elif entity ran');
                for ent in response_entity['response'][entity].dict::keys{
                    if (ent in ent_list){
                        ii = 0;
                        while (max_score < 0.1){
                            
                            best_answer = use.qa_classify(
                                text = answer_list[ii],
                                classes = response_entity['response'][entity][ent]
                            );
                            nn = best_answer['match_idx'];

                            
                            if (best_answer['scores'][nn] > max_score){
                                max_score = best_answer['scores'][nn];
                                entity_response = response_entity['response'][entity][ent];
                                removed_que_entity = entity;
                            }

                            leng = answer_list.length - 1;
                            if (max_score < 0.1){
                                ii +=1;
                                if(ii >= leng){
                                    break;
                                }
                            }
                        }
                        rr = rand.choice(entity_response);


                    }
                }
                
            }
            // elif(rr == ""){ 
            //     std.out('else entity ran');
            //     visitor.respond = true;
            // }
        }

        // std.out("Not answered Que");
        // std.out(tess);
        // if (!visitor.respond and rr ==""){
        //     std.out("if response true");
        //     visitor.respond = true;
        // }
        if(!visitor.respond and removed_que_entity != ""){
            // std.out("item was added in update 2");
            removed_que.list::append(removed_que_entity);
            // std.out(removed_que);
        }


        create_response = flow.gen_response(rr.str, visitor.dialogue_context.dict);
        visitor.response = create_response;
        
        // std.out("visitor.dialogue_context['extracted_sentences']");
        // std.out(visitor.dialogue_context['extracted_sentences']);

        if (!visitor.respond){
            std.out("Required Que ");
            std.out(required_que);
            std.out("Unanswered Que");
            std.out(unanswer_que);
            std.out("Answered Que");
            std.out(ent_list);
            std.out("Removed Que");
            std.out(removed_que);
        }
            



        if (visitor.response) {
            visitor.next_state = here;
            
        }
        elif!(visitor.response){
            std.out("Required Que ");
            std.out(required_que);
            std.out("Unanswered Que");
            std.out(unanswer_que);
            std.out("Answered Que");
            std.out(ent_list);
            std.out("Removed Que");
            std.out(removed_que);
            // std.out("NOTE:: no response\n\n");
            visitor.respond = true;
            // std.out("visitor.next_state");
            // std.out(visitor.next_state);
            visitor.next_state = null;
            
            // std.out(visitor.dialogue_context['extracted_sentences']);

        }
        else: {
            // visitor.next_state
            // std.out("NOTE:: Else event ran\n\n");
            // std.out(visitor.respond);
            // visitor.next_state = null;
            
        }
    }

}







// node memories;

// node memory{
//     has dialogue_context;
//     has image_urls;
// }



// node summary_template:dialogue_state{
//     has name;
//     has extracted_sentences = [];
//     can t5_sum.classify_text;
//     can flow.select_event_response;
//     can flow.fix_sentence;
//     can use.qa_classify;
//     can zs_classifier.classify;

//     has emotion;
//     has sentiment;
//     has zs_event;
//     has first_entry = true;

//     can classify_emotion{
//         emotion_list = file.load_json(global.sentiment_descriptors_path);
//         max_score = global.emotion_score;
        
//         for emotions in emotion_list{
//             best_answer = use.qa_classify(
//                 text = visitor.question,
//                 classes = emotion_list[emotions.str]
//             );
//             nn = best_answer['match_idx'];
            
//             if (best_answer['scores'][nn] > max_score){
//                 max_score = best_answer['scores'][nn];
//                 here.emotion = emotions;
//             }
//         }
//         std.log( "EMOTION: " + " MATCH: ", here.emotion,"   SCORE: " ,max_score);

//         if(here.emotion){
//             sentiments = file.load_json(global.sentiments_path);
//             here.sentiment = rand.choice(sentiments[here.emotion]);
//         }

        
//         // zs_result =  zs_classifier.classify(text=visitor.question, classes=["vacation","birthday","anniversary","funeral","sport"]);

//         // if(visitor.question in zs_result[0]){
//         //     emotion = zs_result[0][visitor.question][0]['value'];
//         //     sentiments = file.load_json(global.sentiments_path);
//         //     here.sentiment = rand.choice(sentiments[emotion]);
//         // }
    


        
//     }

//     can nlu with talk entry {
//         ::classify_intent;
//         ::extract_entities;
//         ::business_logic;

//         state_json = file.load_json(global.train_state_path);
//         event_list = file.load_json(global.events_path);

        

//         for state in state_json{
//             if (here.name == state["name"].str){

//                 if(visitor.extracted_entities and !visitor.respond){
//                     here.extracted_sentences.list::append(visitor.question);
//                 }
//                 if ("event" in  visitor.extracted_entities){
//                     zs_result =  zs_classifier.classify(text=visitor.question, classes=["vacation","birthday","anniversary","funeral","sport"]);
//                     here.zs_event = zs_result[0][visitor.question][0]['value'];
//                 }
//                 arry = flow.select_event_response(state["extracted_item"], state["responses"], visitor.dialogue_context, event_list[here.zs_event]); # select a response
//                 std.out("event_list[here.zs_event]");
//                 std.out(event_list[here.zs_event]);
//                 zs_enitity = zs_classifier.classify(text=visitor.question, classes=event_list[here.zs_event]);
//                 // std.out(state["extracted_item"].dict::keys);

//                 std.out("zs_enitity");
//                 std.out(zs_enitity);

//                 if(arry["name"] != ""){
//                     visitor.response = arry['response'];
//                     if!(visitor.extracted_entities): visitor.dialogue_context[arry['name']] = ""; // add to dialcontext so it would ask for it again
                    
//                     if (here.first_entry){
//                         ::classify_emotion;
//                         here.first_entry = false;
//                         first_response = here.sentiment.str+ " " + arry['response'].str;
//                         visitor.response = first_response;
//                     }
//                     visitor.next_state = here;
//                     visitor.respond = false;
//                 }
//                 elif(arry['name'] == ""){
//                     visitor.next_state = here;

//                     sentence = ' '.str::join(here.extracted_sentences);
//                     tt = t5_sum.classify_text(
//                         text = sentence,
//                         min_length = 30,
//                         max_length = 500
//                     );
//                     new_response = flow.fix_sentence(tt);
//                     visitor.response = new_response;
//                 }
//             }
//         }
//     }
// }

// node response_only_template:dialogue_state{
//     has name;

//     can nlu with talk entry {
//         state_json = file.load_json(global.train_state_path);
//         for state in state_json{
//             if (!visitor.respond) {
//                 if (here.name == state["name"].str){
//                     arry = flow.select_response({}, state['responses'], {});
//                     // arry = flow.select_response(null, state['responses'], null);
//                     // std.out(arry);
//                     visitor.response = arry['response'];
//                     // visitor.response = arry[1];
//                 }
//             }
//         }
//     }

//     can process with talk entry{
//         visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
//     }
// }

// node extract_template:dialogue_state{
//     has name;

//     can nlu with talk entry {
//         ::classify_intent;
//         ::extract_entities;
//         ::business_logic;

//         state_json = file.load_json(global.train_state_path);
//         for state in state_json{
//             if (here.name == state["name"].str){
//                 arry = flow.select_response(state["extracted_item"], state["responses"], visitor.dialogue_context); # select a response
//                 if(arry["name"] != ""){
//                     visitor.response = arry['response'];
//                     visitor.next_state = here;
//                 }
//                 elif(arry['name'] == ""){
//                     my_dict = flow.info_json(state['resource'], visitor.dialogue_context, state['variable'] ); # setup data for response

//                     if(my_dict['info_json'].length != 0){
//                         visitor.extracted_entities = my_dict['info_json'][0];
//                         ::business_logic;
//                     }
//                     else{
//                         ans = flow.gen_response(arry['response'], my_dict, null);
//                         visitor.response = ans;
//                     }
//                 }
//             }
//         }
//     }
// }
