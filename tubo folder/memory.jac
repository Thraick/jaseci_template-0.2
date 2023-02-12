import {*} with './nodes_edges.jac';
import {*} with './tool.jac';

import {*} with 'ai/summary.jac';

walker create_memory {
    can tobu.phrase_to_date ;
    has information;
    has user_context;

    has anchor summary;

    has rootTaken = null;
    has memoryNode = null ;
    has peopleNode = [];
    has file_ids = null;
    has locationNode = null ;
    has  personNodeExists = false;
    has locationNodeExist =false;
    has  emotionNodeExist = false;
    has image_urls = null;

    has r = {};

    root{
        if(!memoryNode): take --> node::memory_dir;
        else : take --> node::meta_dir;
        r["information"]= information;
        r["user_context"]= user_context;
        r["summary"]= summary;
        r["peopleNode"]= peopleNode;
        r["image_urls"]= image_urls;
        r["rootTaken"]= rootTaken;
        r["file_ids"]= file_ids;
        r["locationNode"]= locationNode;
        r["personNodeExists"]= personNodeExists;
    }

    memory_dir{
        if(!information) {
            report:status = 400;
            report "Missing required parameters";
            disengage;
        } 

        rand_id = rand.word() + (rand.integer(0, 99999)).str;

        // std.log("USER CONTEXT: ", user_context);

        subject = spawn here walker::summary(text=user_context);
        summary = spawn here walker::summary(category="description", text=user_context);

        when = "";
        emotion = "";
        location = "";
        people = "";

        if(information['date'] != null and information['date'].type == list): when = information['date'][0];
        if(information['date'] != null and information['date'].type == str): when = information['date'];

        if(information['emotion'] != null): emotion = information['emotion'][0];
        
        if(information['location'] != null and information['location'].type == list): location = information['location'][0];
        if(information['location'] != null and information['location'].type == str): location = information['location'];

        if(information['people'] != null): people = information['people'];

        if(file_ids.type == str){
            file_ids = [file_ids];
        }

        if(image_urls.type ==str){
            image_urls = [image_urls];
        }

        date_modified = date.datetime_now();

        memoryNode = spawn here +[memory_link(memory_id=rand_id)] +> node::memory(id=rand_id, date_created=date.datetime_now(), date_modified=date_modified, subject=subject, summary=summary,  description=user_context, category="",when=when, what="", how=emotion, who=people, where=location, file_ids=file_ids, image_urls=image_urls);

        take net.root();      
    }

    meta_dir {
        if(information["people"] != null){
        for person in  information["people"]{
        rand_id = rand.word() + (rand.integer(0, 99999)).str;
        pnodes = -[people_link]-> ; 
        #pnodes = [];
        for pnd in pnodes{
            if(pnd.name ==person):{
                personNodeExists = true;
                personNode = pnd;
                break;
            }
        }

        if(!personNodeExists){
        personNode = spawn here +[people_link(id=rand_id)] +> node::person(name=person,relation="unknown");
        memoryNode +[people_link(id=rand_id)]+> personNode;
        personNode +[memory_link(memory_id=memoryNode.id)] +>memoryNode;
        peopleNode.list::append(personNode); 
            
        }
        else{
        memoryNode +[people_link(id=rand_id)] +>personNode;
        personNode +[memory_link(memory_id=memoryNode.id)] +>memoryNode;
        personNodeExists = false;
        }
        }
        }

        if(information["location"] != null){
        rand_id = rand.word() + (rand.integer(0, 99999)).str;

        locations = -[location_link]-> ;
        for location in locations{
            //std.out(information["location"]);
            if(location.name == information["location"][0]):{
                locationNode = location;
                locationNodeExist = true;
                break;
            }
        }
        if(!locationNodeExist){
            rand_id = rand.word() + (rand.integer(0, 99999)).str;
            locationNode = spawn here +[location_link(id=rand_id)]  +> node::location(name=information["location"][0],address ="123 house");
            memoryNode +[location_link(id=rand_id)] +>locationNode;
            locationNode +[memory_link(memory_id =memoryNode.id)] +>memoryNode;
        }
        else{
            memoryNode +[location_link(id=rand_id)] +>locationNode;
            locationNode +[memory_link(memory_id=memoryNode.id)] +> memoryNode;
            locationNodeExist = false;
        }

        }


    if(information["emotion"] != null){
        rand_id = rand.word() + (rand.integer(0, 99999)).str;
        emotions = -[emotion_link]-> ;
        for emotion in emotions{
            if(emotion.name ==information["emotion"][0]):{
                emotionNode = emotion;
                emotionNodeExist = true;
                break;
            }
        }

          if(!emotionNodeExist){
            rand_id = rand.word() + (rand.integer(0, 99999)).str;
            emotionNode = spawn here +[emotion_link(id=rand_id)]  +> node::emotion(name=information["emotion"][0]);
            memoryNode +[emotion_link(id=rand_id)] +>emotionNode;
            emotionNode +[memory_link(memory_id =memoryNode.id)] +>memoryNode;
        }
        else{
            memoryNode +[emotion_link(id=rand_id)] +>emotionNode;
            emotionNode +[memory_link(memory_id=memoryNode.id)] +> memoryNode;
            emotionNodeExist = false;
        }
    }

        // report [locationNode,peopleNode,memoryNode,emotionNode];

    } 
    // report [memoryNode];

}

walker get_related_memory {
    # Given a memory, retrieve a number of related memories
    has anchor related_mems = [];
    has ids = [];
    has max_mem = 3;
    has cnt = 0;
    has started = false;


    memory {
       
        if(!started){
            
            started = true;
            take --> node::emotion;
            take --> node::people;
            take --> node::location;
    
        } 
        else {
            #if (cnt < max_mem): report here;
            if(!here.id in ids){
                ids.l::append(here.id); 

                if(here.file_ids == null){
                    related_mems.l::append(
                        {
                            "id" :here.id,
                            "date_created" :here.date_created,
                            "date_modified" :here.date_modified,
                            "subject" : here.subject,
                            "category" :here.category,
                            "when" : here.when,
                            // "file_ids": here.file_ids,
                            "image_urls" : here.image_urls
                        }
                    );
                }else{
                    related_mems.l::append(
                        {
                            "id" :here.id,
                            "date_created" :here.date_created,
                            "date_modified" :here.date_modified,
                            "subject" : here.subject,
                            "category" :here.category,
                            "when" : here.when,
                            // "file_ids": (spawn here walker::get_file_urls(file_ids=[here.file_ids[0]]))[0],
                            // "file_ids": here.file_ids[0],
                            "image_urls" : here.image_urls
                        }
                    );
                }
                

            if(ids.length == 4): disengage ;

            }
           
            
            
        }
    }
    person {
        take -[memory_link]-> node::memory;
    }

    location {
        take -[memory_link]-> node::memory;
    }

    emotion {
        take -[memory_link]-> node::memory;
    }
}

walker get_memories {
    can tobu.sort_date;
    has memories = [];
    has question = null;
    has wlk_ctx = {
        "entities" : {}
    };
    
    root: take --> node::memory_dir;

    memory_dir{

        if(question){
            here::query_memories ;
            here::processMemory;
            here.processedMemories  = [];

            report tobu.sort_date(memories, 'date_modified', '%Y-%m-%dT%H:%M:%S.%f', true);

            // report memories;

        }
        else {

            if(memories.length == 0){
            take -[memory_link]->;
            take here ;
             }
        else {
            for i = 0 to i < memories.length by i+=1{
            for x =0 to x < memories[i]["relatedMemories"].length by x+=1{
                    #std.out(memories[i]["relatedMemories"][x]);
                    if(memories[i]["id"] == memories[i]["relatedMemories"][x]["id"]){

                         memories[i]["relatedMemories"].l::pop(x);
                    }
            }
        }
            // if(memories.length > 3): memories.l::pop(3); // this here only makes 3 memories show
            if(memories.length > 0) : report tobu.sort_date(memories, 'date_modified', '%Y-%m-%dT%H:%M:%S.%f', true);
            else : report memories ;
            
            // report memories;
         }
       

        } 
        

        }
        
    memory {
        if(here.image_urls.type == list){
            memories.list::append({
                "id": here.id,
                "subject": here.subject,
                "how": here.how,
                "who": here.who,
                "where": here.where,
                "when":here.when,
                "summary": here.summary,
                "date_created": here.date_created,
                "date_modified": here.date_modified,
                "category": here.category,
                // "file_ids": (spawn here walker::get_file_urls(file_ids=[here.file_ids[0]]))[0],
                // "file_ids": here.file_ids[0],
                "image_urls" : here.image_urls[0],
                "relatedMemories" :  spawn here walker::get_related_memory
            });
        } else {
            memories.list::append({
                "id": here.id,
                "subject": here.subject,
                "how": here.how,
                "who": here.who,
                "where": here.where,
                "when":here.when,
                "summary": here.summary,
                "date_created": here.date_created,
                "date_modified": here.date_modified,
                "category": here.category,
                // "file_ids": (spawn here walker::get_file_urls(file_ids=here.file_ids))[0],
                // "file_ids": here.file_ids,
                "image_urls" : here.image_urls,
                "relatedMemories" :  spawn here walker::get_related_memory
            });
        }        
   }
}

walker get_memory {
    has id;

    root: take --> node::memory_dir;

    memory_dir {
        take -[memory_link(memory_id==id)]->;
    }

    memory {
        relatedmems = spawn here walker::get_related_memory;
        count = 0 ;
        for mems in relatedmems{
            if(here.id == mems["id"]){
                relatedmems.l::remove(mems);
            }

        }

        report {
            "id": here.id,
            "subject": here.subject,
            "summary": here.summary,
            "description": here.description,
            "how": here.how,
            "where": here.where,
            "when": here.when,
            "who": --> node::person,
            "date_created": here.date_created,
            "date_modified": here.date_modified,
            "category": here.category,
            // "file_ids": spawn here walker::get_file_urls(file_ids=here.file_ids),
            // "file_ids": here.file_ids,
            "image_urls" : here.image_urls,
            "relatedMemories" :  relatedmems,
            "image_urls" : here.image_urls
        };

    }
} 


walker update_memory {

    has id;
    has subject;
    has category; 
    has summary;
    has description;
    has when;
    has what;
    has how;
    has who;
    has where;
    has file_ids;
    has image_urls;

    has date_created;
    has date_modified;

    has everyone = [];

    root{ 
        if(everyone.length == 0){
            take --> node::meta_dir;
        }else{
            take --> node::memory_dir;
        }
    }


    meta_dir {
        pnodes = -[people_link]-> ; 
        #pnodes = [];
        for pnd in pnodes{
            everyone.list::append(pnd.name);
        }

        take net.root();
    }

    memory_dir: take -[memory_link(memory_id==id)]-> node::memory;


    memory {
        date_modified = date.datetime_now();

        if(date_created): here.date_created = date_created;
        if(subject): here.subject = subject;
        if(category): here.category = category;
        if(summary): here.summary = summary;
        if(description): here.description = description;
        if(when): here.when = when;
        if(what): here.what = what;
        if(how): here.how = how;
        
        if(where): here.where = where;
        if(file_ids): here.file_ids = file_ids;
        if(image_urls):here.image_urls = image_urls;

        if(who.type == list){            
            people = -[people_link]-> node::person;

            for p in -[people_link]-> node::person:
                here !-[people_link] -> p;

            people = -[people_link]-> node::person;

            if(who.length > 0){
                for w in who:
                    spawn here +[people_link(id=rand.word() + (rand.integer(0, 99999)).str)]+> node::person(name=w,relation="unknown");
            }

            people = -[people_link]-> node::person;

            who = [];

            for p in people:
                who.list::append(p.context.name);

            here.who = who;
        }

        report here;

        disengage;
    }
}

walker delete_memory {
    has id;
    root: take --> node::memory_dir;
    memory_dir: take -[memory_link(memory_id==id)]-> node::memory;

    memory {
        report here;
        destroy here;
        disengage;
    }
}

walker query_memories {
    has entities = {};
    has memories = [];

    root: take --> node::meta_dir;

    meta_dir {
        if('people' in entities){
            take -[people_link]-> node::person;
        }

        if('emotion' in entities){
            take -[emotion_link]-> node::emotion;
        }

        if('location' in entities){
            take -[location_link]-> node::location;
        }
    }

    memory {
        take -[memory_link]-> ;
    }

    emotion: take -[emotion_link(id==here.id)]-> node::memory;
    person: take -[person_link(id==here.id)]-> node::memory;
    location: take -[location_link(id==here.id)]-> node::memory;

    memory {
        if(here in memories){}else{
            memories.list::append(here);
        }
    }
}



walker querymemory {
    
    has question = false ;
    has wlk_ctx = {
        "entities" : {}
    };

    has memories = [];

    root {
        take -->node::memory_dir ;
    }


    memory_dir{

        here::query_memories ;
        here::processMemory;
        report memories ;


    }

}


walker get_all_memories {
    root: take --> node::memory_dir;

    memory_dir{
        report -[memory_link]-> node::memory;
    }
}

walker delete_all_memories_forever {
    root: take --> node::memory_dir;

    memory_dir{
        take -[memory_link]-> node::memory;
    }

    memory {
        destroy here;
    }
}



walker extract_exif {
    can tobu.extract_exif_from_img ;
    has img = null;

    root {
        std.out(img);
        report tobu.extract_exif_from_img(img);
    }
}