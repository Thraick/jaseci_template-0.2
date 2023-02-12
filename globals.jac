
global main_root = '';
global dialogue_root = '';

global faq_score = 0.2;
global conv_score = 0.5;

global train_state_path = 'utils/data/state.json';
global train_faq_answer_path = 'utils/data/faq_answer.json';
global train_classifer_path = 'utils/data/classifer_data.json';
global train_tfn_ner_path = 'utils/data/tfm_train.json';


// global entity_label =['number', 'account_name', 'month'];
global entity_label =[];

// summary
global sentiment_descriptors_path = "utils/data/summary/sentiment_descriptors.json";
global events_path = "utils/data/summary/events.json";
global sentiments_path = "utils/data/summary/sentiments.json";
global emotion_score = 0.1;
global entity_response_score = 0;

global sentiment_descriptors = {
    "sad": ["sorrowful", "unfortunate", "sad", "unhappy","Gloomy","Disheartened","Pessimistic","Bleak","Miserable","Melancholic","Despondent","Dejected","Dispirited","Heartbroken","Devastated","Desolate","Wretched","Forlorn","Disappointed","Distraught","Grieved","Anguished","Lonely","Hopeless"],
    "happy": ["pleasant", "lovely", "great", "beautiful", "Joyful","Delighted","Ecstatic","Thrilled","Pleased","Grateful","Overjoyed","Blissful","Content","Cheerful","Amused","Elated","Euphoric","Radiant","Exhilarated","Enchanted","Smitten","Infatuated","Enamored","Over the moon"],
    "fear": ["thrilling", "frightening", "unsettling", "disturbing"],
    "anger": ["angry", "frustrating", "hair-pulling", "annoying"],
    "surprised": ["surprising", "insane", "shocking", "jolting"]
};
// text_classify 
// fix transition


global sentiments = {
    "sad": ["I'm sorry to hear that.", "Oh dear, that's so sad!", "I'm terribly sorry to hear that."],
    "happy": ["Awesome!", "I'm so happy for you!", "That's wonderful!", "How nice.."],
    "fear": ["That's scary!", "That's terrifying!"],
    "anger": ["I'm sorry that you're mad, it'll be ok..'", "Try to stay calm, ok?", "I'm sorry that you are angry!"],
    "surprised": ["Wow, that's surprising!", "Amazing!, I know you are surprised indeed!"]
};


// {
//     "birthday": ["emotion", "people", "date", "location", "age", "subject"],
//     "anniversary": ["emotion", "people", "date", "location", "number"],
//     "vacation": ["emotion", "people", "date", "location", "weather"],
//     "funeral": ["emotion", "people", "date", "location"],
//     "sport": ["emotion", "people", "date", "location", "outcome"],
//     "accident": ["emotion", "people", "date", "location"]
// }

/// tubo 


// global candidate_types = ['birthday', 'wedding', 'sport', 'trip', 'anniversary', 'engagement', 'retirement', 'graduation', 'date'];
global candidate_types = ['wedding', 'sport'];

global emotion = ["sad", "happy", "fear", "anger", "surprised"];

global sentiment_descriptors = {
    "sad": ["sorrowful", "unfortunate", "sad", "unhappy"],
    "happy": ["pleasant", "lovely", "great", "beautiful"],
    "fear": ["thrilling", "frightening", "unsettling", "disturbing"],
    "anger": ["angry", "frustrating", "hair-pulling", "annoying"],
    "surprised": ["surprising", "insane", "shocking", "jolting"]
};

global Relatedmemories = [];

global sentiments = {
    "sad": ["I'm sorry to hear that.", "Oh dear, that's so sad!", "I'm terribly sorry to hear that."],
    "happy": ["Awesome!", "I'm so happy for you!", "That's wonderful!", "How nice.."],
    "fear": ["That's scary!", "That's terrifying!"],
    "anger": ["I'm sorry that you're mad, it'll be ok..'", "Try to stay calm, ok?", "I'm sorry that you are angry!"],
    "surprised": ["Wow, that's surprising!", "Amazing!, I know you are surprised indeed!"]
};

global capture_memory_prompts = [
    "Tell me all about this memory you'd like me to capture",
    "If you're sharing, I'm listening..",
    "Tell me about this moment you'd like to capture ...",
    "A new memory? Tell me all about it...",
    "Tell me about your memory, things like where and when it happened and how you were feeling, then."
];

global affirmative_and_negative_path = "data/affirmative_and_negative.json";
global affirmative_negative_threshold = 0.5;