public class CustomLabelBatchUpdater {
    public static void updateLabelsFromStaticResource() {
        StaticResource resource = [SELECT Body,name FROM StaticResource WHERE Name = 'masked_custom_labels' LIMIT 1];

        String jsonContent = resource.Body.toString();
        
        System.debug('JSON Content: ' + jsonContent);

        if (String.isBlank(jsonContent)) {
            System.debug('JSON Content is empty or null. Please check the static resource content.');
            return;
        }

        try {
            List<LabelData> labels = (List<LabelData>) JSON.deserialize(jsonContent, List<LabelData>.class);
            
            System.debug('Parsed Labels: ' + labels);
            for (LabelData label : labels) {
                updateCustomLabel(label.Name, label.Value);
            }
        } catch (System.JSONException e) {
            System.debug('Error parsing JSON: ' + e.getMessage());
        }
    }

    private static void updateCustomLabel(String labelName, String newLabelValue) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        
        MetadataService.IReadResult readResult = service.readMetadata('CustomLabel', new String[] { labelName });
        
        if (readResult.getRecords().size() > 0) {
            MetadataService.CustomLabel customLabel = (MetadataService.CustomLabel) readResult.getRecords()[0];
            
            customLabel.value = newLabelValue;
            
            MetadataService.SaveResult[] results = service.updateMetadata(new MetadataService.Metadata[] { customLabel });
            
            if (results[0].success) {
                System.debug('Custom Label updated successfully: ' + labelName);
            } else {
                MetadataService.Error[] errors = results[0].errors;
                for (MetadataService.Error error : errors) {
                    System.debug('Error updating custom label: ' + error.message);
                }
            }
        } else {
            System.debug('Custom Label not found: ' + labelName);
        }
    }

    public class LabelData {
        public String Id;
        public String Name;
        public String Value;
        public Attributes attributes;
    }

    public class Attributes {
        public String type;
        public String url;
    }
}