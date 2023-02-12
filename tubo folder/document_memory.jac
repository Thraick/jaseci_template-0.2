import {*} with './nodes_edges.jac';
import {*} with './memory.jac';
import {*} with './sport.jac';
import {*} with './tool.jac';

node document_memory:dialogue_state {
    has name = "document_memory";

    can tobu.phrase_to_date;
    can tobu.extract_exif_from_img;
    can use.encode, use.cos_sim_score;
    can bi_enc.infer;

    can nlu {
        if (!visitor.wlk_ctx["intent"]): ::classify_intent;
        ::extract_entities;

        if(visitor.wlk_ctx["starting"] == false){
            // if("emotion" not in visitor.wlk_ctx["entities"]){
            //     visitor.wlk_ctx["last_entity"] = "emotion";
            // }
            if ("people" not in visitor.wlk_ctx["entities"]){
                visitor.wlk_ctx["last_entity"] = "people";
            }
            elif ("location" not in visitor.wlk_ctx["entities"]){
                visitor.wlk_ctx["last_entity"] = "location";
            }
            elif ("date" not in visitor.wlk_ctx["entities"]){
                visitor.wlk_ctx["last_entity"] = "date";
            }
            else {
                visitor.wlk_ctx["last_entity"] = null;
            }
        }
    }

    can process {

        if(visitor.wlk_ctx["intent"] == "no") {
            last_entity = visitor.wlk_ctx["last_entity"];
            if(last_entity != "emotion"){
                visitor.wlk_ctx["entities"][last_entity] = null;
            }
        }

        if("emotion" in visitor.wlk_ctx["entities"]){
            if(visitor.wlk_ctx["entities"]["emotion"] != null){
            text_emb = use.encode(visitor.wlk_ctx["entities"]["emotion"][0])[0];
            cand_embs = use.encode(global.emotion);
            
            max_score = 0;
            max_cand = 0;
            cand_idx = 0;
            for cand_emb in cand_embs {
                cos_score = use.cos_sim_score(cand_emb, text_emb);
                if (cos_score > max_score) {
                    max_score = cos_score;
                    max_cand = cand_idx;
                }
                cand_idx += 1;
            }

            visitor.wlk_ctx["entities"]["emotion"] = [global.emotion[max_cand]];
            }
        }

        if(visitor.file_url != null){
            if(visitor.file_url.type == str){
                res = tobu.extract_exif_from_img(visitor.file_url);

                if('DateTime' in res and 'Location' in res){
                    if(res['DateTime'] != null){
                        visitor.wlk_ctx["entities"]["date"] = res['DateTime'];
                    }

                    if(res['Location'] != null){
                        visitor.wlk_ctx["entities"]["location"] = res['Location'];
                    }
                }
            }
        }

        if(visitor.wlk_ctx["trigger_confirmed"] == false){
            // Check entity transition
            required_entities = -[entity_transition]->.edge[0].context["entities"];

            if(visitor.wlk_ctx["intent"] == "abort") {
                next_state = -[intent_transition(intent==visitor.wlk_ctx["intent"])]->;

                visitor.wlk_ctx["next_state"] = next_state[0];
                visitor.wlk_ctx["prev_state"] = here;
            }
            elif ("location" in visitor.wlk_ctx["entities"] and "people" in visitor.wlk_ctx["entities"] and "date" in visitor.wlk_ctx["entities"] and "emotion" in visitor.wlk_ctx["entities"]) {

                intent_labels = ["sport", "trip", "birthday", "anniversary"];
                
                if("event" in visitor.wlk_ctx["entities"]){
                    if(visitor.wlk_ctx["entities"]["event"] != null){
                            text_emb = use.encode(visitor.wlk_ctx["entities"]["event"][0])[0];
                            cand_embs = use.encode(intent_labels);
                            
                            max_score = 0;
                            max_cand = 0;
                            cand_idx = 0;
                            for cand_emb in cand_embs {
                                cos_score = use.cos_sim_score(cand_emb, text_emb);
                                if (cos_score > max_score) {
                                    max_score = cos_score;
                                    max_cand = cand_idx;
                                }
                                cand_idx += 1;
                            }

                        visitor.wlk_ctx["entities"]["event_data"] = visitor.wlk_ctx["entities"]["event"];
                        visitor.wlk_ctx["entities"]["event"] = [intent_labels[max_cand]];

                        next_state = -[intent_transition(intent==visitor.wlk_ctx["entities"]["event"][0])]->;

                        visitor.wlk_ctx["next_state"] = next_state[0];
                        visitor.wlk_ctx["prev_state"] = here;

                        visitor.wlk_ctx["trigger_confirmed"] = true;
                    }else {
                        visitor.wlk_ctx["next_state"] = -[entity_transition]->[0];
                        visitor.wlk_ctx["prev_state"] = here;
                    }
                    
                }else{
                    visitor.wlk_ctx["next_state"] = -[entity_transition]->[0];
                    visitor.wlk_ctx["prev_state"] = here;
                }

            }
            else {
                visitor.wlk_ctx["respond"] = true;
            }
        }else{
            visitor.wlk_ctx["next_state"] = -[entity_transition]->[0];
            visitor.wlk_ctx["prev_state"] = here;
        }
    }

    can nlg {

        if(visitor.wlk_ctx["starting"] == false){
            
            //no indication of emotion, prompt for it
            if("emotion" not in visitor.wlk_ctx["entities"]) {
                if("people" in visitor.wlk_ctx["entities"]) {
                    if("subject" in visitor.wlk_ctx["entities"]){
                        visitor.response = "Did you have fun at " + visitor.wlk_ctx["entities"]["subject"][0] + "'s celebration?";
                    }elif(visitor.wlk_ctx['entities']['people'] != null){
                        if(visitor.wlk_ctx['entities']['people'][0] != "me"){
                            visitor.response = "Describe how you felt in this memory with " + visitor.wlk_ctx["entities"]["people"][0] + "?";
                        }
                    }
                }
                elif("location" in visitor.wlk_ctx["entities"]){
                    visitor.response = visitor.wlk_ctx["entities"]["location"][0] + ", hmmm. Was there anyone else with you?";
                }
                else{
                    visitor.response = "Tell me how you feel about this memory...";
                }
            }
            //we have emotion...
            elif ("people" not in visitor.wlk_ctx["entities"]) {
                r = global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]][rand.integer(0, global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]].length - 1)];
                visitor.response = r + " Was anyone else with you?";
            }              
            elif ("location" not in visitor.wlk_ctx["entities"]) {
                //r = global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]][rand.integer(0, global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]].length - 1)];
                visitor.response = " Where was this, exactly?";
            }
            elif ("date" not in visitor.wlk_ctx["entities"]) {
                r = global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]][rand.integer(0, global.sentiments[visitor.wlk_ctx["entities"]["emotion"][0]].length - 1)];
                visitor.response = r + " when was this?";
            }          
            else {
                r = global.capture_memory_prompts[ rand.integer(0, (global.capture_memory_prompts.length - 1) ) ];
                visitor.response = r;
            }
            
        } else {
                r = global.capture_memory_prompts[ rand.integer(0, (global.capture_memory_prompts.length - 1) ) ];
                visitor.response = r;
                visitor.wlk_ctx["starting"] = false;
        }
    }
}

node document_memory_confirmed:dialogue_state {
    can use.encode, use.cos_sim_score;
    can tobu.phrase_to_date;

    has name = "document_memory_confirmed";
    has emotion;
    has ee_info = null;

    can nlu {
        std.out("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
        std.out("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
        std.out(visitor.wlk_ctx["user_context"]);
        response = sentence.fix_sentence(visitor.wlk_ctx["user_context"]);
        visitor.wlk_ctx["user_context"] = response;
        std.out(visitor.wlk_ctx["user_context"]);
        std.out("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
        std.out("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
        if(visitor.wlk_ctx["intent"] == "no"){
            visitor.wlk_ctx["entities"]["date"] = date.date_now(); 
        }

        if(visitor.wlk_ctx["entities"] != {}){

            if("emotion" in visitor.wlk_ctx["entities"]){
                if(visitor.wlk_ctx["entities"]["emotion"] != null){
                text_emb = use.encode(visitor.wlk_ctx["entities"]["emotion"][0])[0];
                cand_embs = use.encode(global.emotion);
                
                max_score = 0;
                max_cand = 0;
                cand_idx = 0;
                for cand_emb in cand_embs {
                    cos_score = use.cos_sim_score(cand_emb, text_emb);
                    if (cos_score > max_score) {
                        max_score = cos_score;
                        max_cand = cand_idx;
                    }
                    cand_idx += 1;
                }

                visitor.wlk_ctx["entities"]["emotion"] = [global.emotion[max_cand]];
                }
            }

            

            if("date" in visitor.wlk_ctx["entities"]){

                date_slot = visitor.wlk_ctx["entities"]["date"];

                if(date_slot.type == str){
                    visitor.wlk_ctx["entities"]["date"] = tobu.phrase_to_date(visitor.wlk_ctx["entities"]["date"]); 
                }

                if(date_slot.type == list){
                    visitor.wlk_ctx["entities"]["date"] = tobu.phrase_to_date(visitor.wlk_ctx["entities"]["date"][0]); 
                }
            
            }

            if("people" in visitor.wlk_ctx["entities"] and visitor.wlk_ctx["intent"] != "no"){
                if(visitor.wlk_ctx["entities"]["people"] != null){
                    visitor.wlk_ctx["entities"]["people"] = spawn here walker::remove_duplicate(record=visitor.wlk_ctx["entities"]["people"]);
                    visitor.wlk_ctx["entities"]["people"] = spawn here walker::map_entity_value_to_another_value(current_value="my", new_value="you", record=visitor.wlk_ctx["entities"]["people"]);
                    visitor.wlk_ctx["entities"]["people"] = spawn here walker::map_entity_value_to_another_value(current_value="me", new_value="you", record=visitor.wlk_ctx["entities"]["people"]);
                }
            }


            if(visitor.image_urls){
                visitor.wlk_ctx["summary"] = spawn net.root() walker::create_memory(information=visitor.wlk_ctx["entities"], user_context = visitor.wlk_ctx['user_context'],image_urls=visitor.image_urls);
            }
            else {
                visitor.wlk_ctx["summary"] = spawn net.root() walker::create_memory(information=visitor.wlk_ctx["entities"], user_context = visitor.wlk_ctx['user_context']);
            }

            if(visitor.wlk_ctx["entities"]["emotion"] == null): emotion = null;
            if(visitor.wlk_ctx["entities"]["emotion"] != null): emotion = visitor.wlk_ctx["entities"]["emotion"][0];
            
            visitor.wlk_ctx["temporary_data"] = visitor.wlk_ctx["entities"];
            visitor.wlk_ctx["entities"] = {};
            visitor.wlk_ctx["user_context"] = "";
            visitor.wlk_ctx["trigger_emotion"] = true;
            visitor.wlk_ctx["trigger_confirmed"] = false;
        } 
    }

    can reset {
        visitor.wlk_ctx["starting"] = true;
    }

    can nlg {
        visitor.response = "";
        subject_text = "";
        people_text = "";
        ee_info = visitor.wlk_ctx["temporary_data"];
        
        if(visitor.wlk_ctx["starting"] == false) {
            if(ee_info['location'].type == str){
                ee_info['location'] = [ee_info['location']];
            }
            if(ee_info['date'].type == str){
                ee_info['date'] = [ee_info['date']];
            }
            if(ee_info["people"] == null){
                ee_info["people"] = ["you"];
            } else {
                
                //let's prepare people text
                index = 0;
                if(ee_info["people"].length > 1) {
                    for person in ee_info["people"] { 
                        
                        if(index < ((ee_info["people"].length)-1) ): people_text += person + ", ";
                        else: people_text += " and " + person;
                        index += 1;
                    }
                } else {
                    people_text = ee_info["people"][0];
                } 
            } 
            if(ee_info["date"] == null){
                ee_info["date"] = ["a previous occasion"];
            }
            if(ee_info["location"] == null){
                ee_info["location"] = ["an undisclosed location"];
            }
            if("event" not in ee_info){
                ee_info["event"] = ["normal"];
            }
            if("subject" in ee_info) {
                //let's prepare subject text
                index = 0;
                if(ee_info["subject"].length > 1) {
                    for subject in ee_info["subject"] { 
                        
                        if(index < ((ee_info["subject"].length)-1) ): subject_text += subject + ", ";
                        else: subject_text += " and " + subject;
                        index += 1;
                    }
                } else {
                   subject_text = ee_info["subject"][0];
                }  
            }

            std.log("EEINFO: ", ee_info);
            std.log("SUMMARY: ", visitor.wlk_ctx["summary"]);

           l_outcome = "lost lose";
            w_outcome = "won win";

            // if("outcome" in ee_info){
            //     if(ee_info["outcome"][0] in l_outcome){
            //         emotion = "sad";
            //     }elif(ee_info["outcome"][0] in w_outcome){
            //         emotion = "happy";
            //     }
            // }
            
            //if(emotion) {
            descriptor = global.sentiment_descriptors[ee_info["emotion"][0]][rand.integer(0, global.sentiment_descriptors[ee_info["emotion"][0]].length - 1)];
            sentiment = global.sentiments[ee_info["emotion"][0]][rand.integer(0, global.sentiments[ee_info["emotion"][0]].length - 1)];

            visitor.response = "What a " + descriptor + " memory."; 

            visitor.response = visitor.response 
            + " I've recorded that on " + ee_info["date"][0] 
            + " you were in " + ee_info["location"][0];

            // //add people statement if not by yourself...
            if("you" not in ee_info["people"]) {
                visitor.response = visitor.response 
                + " with " + people_text + ".";
            } 
        
            if("sport" in ee_info["event"]) {
                visitor.response = visitor.response 
                + " You were at a " + ee_info["event_data"][0]
                + " where the " + ee_info["team"][0] + " " + ee_info["outcome"][0];
            }
            elif("trip" in ee_info["event"]){
                visitor.response = visitor.response 
                + " You were on a " + ee_info["event_data"][0] 
                + " where you " + ee_info["activity"][0];
            }
            elif("birthday" in ee_info["event"]){
                visitor.response = visitor.response 
                + " It was " + ee_info["subject"][0] +  "'s " 
                + ee_info["event_data"][0] 
                + " who turned " + ee_info["age"][0];
            }
            elif("anniversary" in ee_info["event"]){
                visitor.response = visitor.response
                + " It was " + subject_text + "'s " 
                + ee_info["event_data"][0];
            }
            
                        
            ::reset;
        }else {
            r = global.capture_memory_prompts[ rand.integer(0, (global.capture_memory_prompts.length - 1) ) ];
            visitor.response = r;
            visitor.wlk_ctx["starting"] = false;
            ::reset;
        }
    }
}

node document_memory_abort_confirm:dialogue_state {
    has name = "document_memory_abort_confirm";
    can nlu {
        if (!visitor.wlk_ctx["intent"]): ::classify_intent;
    }
    can process {
        if(visitor.wlk_ctx["intent"] == "no"){
            visitor.wlk_ctx["next_state"] = -[intent_transition(intent=="document memory")]->[0];
            visitor.wlk_ctx["prev_state"] = here; 
        }elif (visitor.wlk_ctx["prev_state"]){
            visitor.wlk_ctx["respond"] = true;
        }else {
            visitor.wlk_ctx["next_state"] = -[intent_transition(intent==visitor.wlk_ctx["intent"])]->[0];
            visitor.wlk_ctx["prev_state"] = here;
        }
    }
    can nlg {
        visitor.response = "Ok. Are you sure you'd like me to quit capturing this memory for you?";
    }
}

node document_memory_cancelled:dialogue_state {
    has name = "document_memory_cancelled";
    can nlu {
        visitor.wlk_ctx["entities"] = {};
        visitor.wlk_ctx["user_context"] = "";
        visitor.wlk_ctx["trigger_emotion"] = true;
        visitor.wlk_ctx["trigger_confirmed"] = false;
    }
    can nlg {
        visitor.response = "No worries! Talk to me whenever you'd like to document anything.";
        here::nlu;
    }
}