# Arda Mavi

import coremltools
from database_process import get_data
from keras.models import model_from_json

with open('Model/model.json', 'r') as model_file:
    model = model_file.read()
model = model_from_json(model)
model.load_weights("Model/weights.h5")

scale = 1/255.
class_labels = []

calsses = get_data('SELECT char FROM "id_char"')
for a_class in calsses:
    class_labels.append(a_class[0])

coreml_model = coremltools.converters.keras.convert(model, input_names='image', image_input_names='image', output_names='class', class_labels=class_labels, image_scale=scale)

coreml_model.author = 'Sesgoritma'
coreml_model.license = 'Apache License 2.0'
coreml_model.short_description = 'Vocalization sign language.'

coreml_model.save('Sesgoritma.mlmodel')

