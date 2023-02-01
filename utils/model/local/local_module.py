import re
from jaseci.actions.live_actions import jaseci_action  # step 1

@jaseci_action(act_group=["local"], allow_remote=True)
def entity_value(utterance:str, utterance_list:list):
    lis = []
    if utterance_list:
        for utterance in utterance_list:
            m = re.findall(r"\[([A-Za-z0-9_-]+)\]", utterance)
            n = re.findall(r"\(([A-Za-z0-9_-]+)\)", utterance)

            data = {"value": m, "entity": n, "utterance": utterance}
            lis.append(data)
    else:
        m = re.findall(r"\[([A-Za-z0-9_-]+)\]", utterance)
        n = re.findall(r"\(([A-Za-z0-9_-]+)\)", utterance)

        data = {"value": m, "entity": n, "utterance": utterance}
        lis.append(data)
    return lis


from transformers import T5Tokenizer, T5ForConditionalGeneration
from pprint import pprint

@jaseci_action(act_group=["local"], allow_remote=True)
def paraphraser(text:str):
    model = T5ForConditionalGeneration.from_pretrained('prithivida/parrot_paraphraser_on_T5')
    tokenizer = T5Tokenizer.from_pretrained('prithivida/parrot_paraphraser_on_T5')

    # input_text = "yesterday was Anna's birthday. This was taken at home in Ann Arbor." 
    # input_text = "yesterday was Anna's birthday. This was taken at home in Ann Arbor. we had an amazing time." 
    # input_text = "yesterday was Anna's birthday. This was taken at home in Ann Arbor. we had an amazing time,  Anna is 22 years old" 
    input_text = "yesterday was Anna's birthday This was taken at home in Ann Arbor we had an amazing time  Anna is 22 years old it was just my friends" 

    # input_text = "Natural Language Processing can improve the quality life."

    batch = tokenizer(input_text, return_tensors='pt')

    # generated_ids = model.generate( batch['input_ids'],
    #                                 num_beams=5,
    #                                 num_return_sequences=5,
    #                                 temperature=1.5,
    #                                 num_beam_groups=5,
    #                                 diversity_penalty=2.0,
    #                                 no_repeat_ngram_size=2,
    #                                 early_stopping=True,
    #                                 length_penalty=2.0,
    #                                 max_new_tokens = 200
    #                                 )

    generated_ids = model.generate( batch['input_ids'],
                                    num_beams=5,
                                    temperature=1.5,
                                    no_repeat_ngram_size=2,
                                    early_stopping=True,
                                    length_penalty=2.0,
                                    max_new_tokens = 200
                                    )

    generated_sentence = tokenizer.batch_decode(generated_ids, skip_special_tokens=True)
    return generated_sentence

# input_text = "yesterday was Anna's birthday This was taken at home in Ann Arbor we had an amazing time  Anna is 22 years old it was just my friends" 
# tt = paraphraser(input_text)
# pprint( tt)
