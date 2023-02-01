actions load module jaseci_ai_kit.use_qa
actions load module jaseci_ai_kit.bi_enc
actions load module jaseci_ai_kit.tfm_ner
actions load module jaseci_ai_kit.use_enc
actions load module jaseci_ai_kit.t5_sum
actions load module jaseci_ai_kit.zs_classifier
actions load module jaseci_ai_kit.cl_summer

actions load local utils/model/local/flow.py
actions load local utils/model/local/twilio_bot.py
actions load local utils/model/local/local_module.py

graph delete active:graph
jac build main.jac
graph create -set_active true
sentinel register -set_active true -mode ir main.jir

walker run init



walker run talk -ctx "{\"question\": \"yesterday was Anna's birthday.\"}"
walker run talk -ctx "{\"question\": \"yesterday was Anna's birthday. we went on a vacation\"}"
// walker run talk -ctx "{\"question\": \"we celebrated her birthday at home.\"}"
walker run talk -ctx "{\"question\": \"This was taken at home in Ann Arbor\"}"
walker run talk -ctx "{\"question\": \"it was amazing\"}"
walker run talk -ctx "{\"question\": \"Anna is 22 years old\"}"
walker run talk -ctx "{\"question\": \"it was just my friends\"}"
walker run talk -ctx "{\"question\": \"it was mostly sunny there\"}"



walker run talk -ctx "{\"question\": \"This was taken at home in Ann Arbor. we had an amazing time\"}"


walker run talk -ctx "{\"question\": \" yes, save it\"}"
walker run talk -ctx "{\"question\": \"Let's not save it\"}"
walker run talk -ctx "{\"question\": \"yes Absolutely\"}"
walker run talk -ctx "{\"question\": \"no\"}"



walker run talk -ctx "{\"question\": \"yesterday was Anna's birthday.\"}"
walker run talk -ctx "{\"question\": \"john and tim was there and they were anna's oldest friends\"}"
walker run talk -ctx "{\"question\": \"no\"}"
walker run talk -ctx "{\"question\": \"It was really amazing\"}"
walker run talk -ctx "{\"question\": \"We ate cake and play cricket\"}"





// walker run talk -ctx "{\"question\": \"hello, how are you\"}"
// walker run talk -ctx "{\"question\": \"later\"}"

// walker run talk -ctx "{\"question\": \"I went to a trip in france with my friends yesterday\"}"
// walker run talk -ctx "{\"question\": \"it was amazing\"}"
// walker run talk -ctx "{\"question\": \"it was mostly sunny there\"}"

// walker run talk -ctx "{\"question\": \"Today is Anna birthday, she's been trying to stand on her own. It fills me up with such a sense of joy to see my little girl blossom before me.\"}"
// walker run talk -ctx "{\"question\": \"it was just my friends\"}"
// walker run talk -ctx "{\"question\": \"This was taken at home in Ann Arbor\"}"
// walker run talk -ctx "{\"question\": \"Anna is 22 years old\"}"

// walker run talk -ctx "{\"question\": \"yes Absolutely\"}"
// walker run talk -ctx "{\"question\": \"Yes, save it\"}"
// walker run talk -ctx "{\"question\": \"Please don't save it\"}"
// walker run talk -ctx "{\"question\": \"forget it\"}"
// walker run talk -ctx "{\"question\": \"Where can I pay my bill?\"}"









### tfm_ner // note for some reason tfm_ner_train only work on the server 

walker run tfm_ner_train -ctx "{\"train_file\": \"utils/data/tfm_train.json\"}"
walker run tfm_ner_infer -ctx "{\"labels\": [\"number\",\"accountName\",\"month\",\"accountNumber\"]}"
walker run tfm_ner_infer -ctx "{\"labels\": [\"event\",\"name\",\"activity\",\"emotion\",\"people\",\"subject\",\"age\",\"location\"]}"
walker run tfm_ner_save_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_load_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_delete




// pip install cmake



graph get -mode dot -o .main.dot
dot -Tpng .main.dot -o .main.png



"trip": ["emotion", "people", "date", "location", "weather"],
"football": ["emotion", "people", "date", "location"]


walker run talk -ctx "{\"question\": \"i went too a birthday party\"}"

walker run talk -ctx "{\"question\": \"later\"}"
